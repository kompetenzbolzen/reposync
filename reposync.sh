#!/bin/bash

ARGV=($@)
ARGC=${#ARGV[@]}

API_BASE="https://api.github.com"

# ['name']='ssh_url' # name with .git suffix
declare -A GH_REPOS

function curl_wrapper() {
	RAW_CURL=$(curl -s -w "%{http_code}" $@; exit $?)
	RET=$?
	[ $RET -ne 0 ] && >&2 echo curl failed with $RET && exit 1

	HTTP_CODE=$(tail -n 1 <<< "$RAW_CURL")
	[ $HTTP_CODE -ge 300 ] && >&2 echo HTTP error $HTTP_CODE && exit 1

	head -n -1 <<< "$RAW_CURL"
}

# create new repository for $USERNAME
# 1: name
function github_create_repo() {
	[ -z "$TOKEN" ] && >&2 echo TOKEN not set. No write access. && exit 1
	JSON_RETURN=$(curl_wrapper -X POST -H "Content-Type: application/json" -u $USERNAME:$TOKEN \
		-d "{\"name\":\"$1\"}" "$API_BASE/user/repos"; exit $? )
	[ $? -ne 0 ] && exit 1

	GH_REPOS[$1.git]=$(jq ".ssh_url" <<< $JSON_RETURN | tr -d '"')
}

function github_update_repo_list() {
	GH_REPOS=()

	unset CURL_USER
	[ ! -z "$TOKEN" ] && CURL_USER="-u $USERNAME:$TOKEN"
	
	JSON_REPOS=$(curl_wrapper $CURL_USER "$API_BASE/users/$USERNAME/repos"; exit $?)
	[ $? -ne 0 ] && exit 1

	GH_REPOS_COUNT=$(jq ". | length" <<< "$JSON_REPOS")
	
	for (( i=0; i<$GH_REPOS_COUNT; i++ )); do
		name="$(jq ".[$i].name" <<< "$JSON_REPOS" | tr -d '"' ).git"
		GH_REPOS[$name]=$(jq ".[$i].ssh_url" <<< "$JSON_REPOS" | tr -d '"' )
	done
}

[ -f "$HOME/settings.sh" ] && source $HOME/settings.sh

github_update_repo_list

LOCAL_REPOS=( $(for repo in $(ls -d $REPO_DIR/*.git/ 2> /dev/null); do basename $repo; done ) )

TO_CLONE=( $(comm -23 <(printf "%s\n" "${!GH_REPOS[@]}" | sort) \
	<(printf "%s\n" "${LOCAL_REPOS[@]}" | sort) ) )
TO_CREATE=( $(comm -13 <(printf "%s\n" "${!GH_REPOS[@]}" | sort) \
	<(printf "%s\n" "${LOCAL_REPOS[@]}" | sort) ) )
TO_PUSH=( $(comm -12 <(printf "%s\n" "${!GH_REPOS[@]}" | sort) \
	<(printf "%s\n" "${LOCAL_REPOS[@]}" | sort) ) )

echo TO CLONE
printf "%s\n" "${TO_CLONE[@]}"
echo
echo TO CREATE
printf "%s\n" "${TO_CREATE[@]}"
echo
echo TO PUSH
printf "%s\n" "${TO_PUSH[@]}"

echo

for repo in "${TO_CLONE[@]}"; do
	mkdir "$REPO_DIR/$repo"
	git clone --bare \
		"${GH_REPOS[$repo]}" "$REPO_DIR/$repo"

	git -C "$REPO_DIR/$repo" remote add github_sync "${GH_REPOS[$repo]}"
done

for repo in "${TO_CREATE[@]}"; do
	github_create_repo ${repo%.git}

	git -C "$REPO_DIR/$repo" remote | grep -q github_sync && \
		git -C "$REPO_DIR/$repo" remote remove github_sync

	git -C "$REPO_DIR/$repo" remote add github_sync "${GH_REPOS[$repo]}"
	git -C "$REPO_DIR/$repo" push github_sync
done

for repo in "${TO_PUSH[@]}"; do
	! git -C "$REPO_DIR/$repo" remote | grep -q github_sync && \
		git -C "$REPO_DIR/$repo" remote add github_sync "${GH_REPOS[$repo]}"

	git -C "$REPO_DIR/$repo" push --all github_sync
done

echo
echo Done.
