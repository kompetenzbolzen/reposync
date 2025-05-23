#!/bin/bash

# reposync.sh
# Syncs a folder to GitHub

# required setup:
# - different user for script (no specific name needed) and git access (git)
#
# Usage:
#	reposync.sh <CONFIG FILE>
#
# Config file: 
# Sourcable bash script setting the variables:
#	USERNAME	GitHub Username
#	TOKEN		Password or Token
#	REPO_DIR	Directory on the filesystem
#	PRIVATE		Treat repositories as private (true/false)
#	LIMIT		Limit syncing to repos specified in LIMIT_TO (true/false)
#	LIMIT_TO	Array of repos to limit syncing to

ARGV=($@)
ARGC=${#ARGV[@]}

API_BASE="https://codeberg.org/api/v1"

# ['name']='ssh_url' # name with .git suffix
declare -A GH_REPOS

function url_inject_credentials() {
	sed -n -e "s/^\(https:\/\/\)\(.*\)$/\1$USERNAME:$TOKEN@\2/p"
}

function curl_wrapper() {
	local CURL_RETURN
	CURL_RETURN=$( curl -s -w "%{http_code}" "$@" ; exit $? )
	local RET=$?
	[ $RET -ne 0 ] && >&2 echo cURL code $RET && return 1

	head -n -1 <<< "$CURL_RETURN"

	local HTTP_CODE=$(tail -n 1 <<< "$CURL_RETURN")
	[ $HTTP_CODE -ge 300 ] && >&2 echo HTTP Code $HTTP_CODE && return 1

	return 0
}

# create new repository for $USERNAME
# 1: name
function github_create_repo() {
	[ -z "$TOKEN" ] && >&2 echo TOKEN not set. No write access. && exit 1

	echo Creating $1

	local JSON_RETURN
	JSON_RETURN=$(curl_wrapper -X POST -H "Content-Type: application/json" \
		-u $USERNAME:$TOKEN \
		-d "{\"name\":\"$1\",\"private\":false}" "$API_BASE/user/repos"; exit $? )

	echo "$JSON_RETURN"

	[ $? -ne 0 ] && exit 1

	GH_REPOS[$1.git]=$(jq -r ".clone_url" <<< "$JSON_RETURN" | url_inject_credentials )
}

function github_update_repo_list() {
	GH_REPOS=()

	local CURL_USER=""
	[ ! -z "$TOKEN" ] && CURL_USER="-u $USERNAME:$TOKEN"

	local JSON_REPOS
	JSON_REPOS=$(curl_wrapper -u $USERNAME:$TOKEN \
		"$API_BASE/user/repos?limit=100"; exit $?)
	[ $? -ne 0 ] && jq ".message" <<< "$JSON_REPOS" && exit 1

	GH_REPOS_COUNT=$(jq ". | length" <<< "$JSON_REPOS")
	
	for (( i=0; i<$GH_REPOS_COUNT; i++ )); do
		name="$(jq -r ".[$i].name" <<< "$JSON_REPOS" ).git"
		GH_REPOS[$name]=$(jq -r ".[$i].clone_url" <<< "$JSON_REPOS" | url_inject_credentials )
	done
	
	echo ${GH_REPOS[*]}
}

[ ! -f "$1" ] && echo Config file not found && exit 1

source "$1"

[ -z "$USERNAME" -o -z "$TOKEN" ] && echo GitHub credentials config error. && exit 1

[ ! -d "$REPO_DIR" ] && echo Repo directory does not exist. && exit 1

[ "$PRIVATE" != "true" ] && PRIVATE=false

github_update_repo_list

LOCAL_REPOS=( $(for repo in $(ls -d $REPO_DIR/*.git/ 2> /dev/null); do basename $repo; done ) )

TO_CLONE=( $(comm -23 <(printf "%s\n" "${!GH_REPOS[@]}" | sort) \
	<(printf "%s\n" "${LOCAL_REPOS[@]}" | sort) ) )
TO_CREATE=( $(comm -13 <(printf "%s\n" "${!GH_REPOS[@]}" | sort) \
	<(printf "%s\n" "${LOCAL_REPOS[@]}" | sort) ) )
TO_PUSH=( $(comm -12 <(printf "%s\n" "${!GH_REPOS[@]}" | sort) \
	<(printf "%s\n" "${LOCAL_REPOS[@]}" | sort) ) )

if [ "$LIMIT" = "true" -a "${#LIMIT_TO[@]}" -gt 0 ]; then
	TO_CLONE=( $(comm -12 <(printf "%s\n" "${LIMIT_TO[@]}" | sort) \
		<(printf "%s\n" "${TO_CLONE[@]}" | sort) ) )

	TO_CREATE=( $(comm -12 <(printf "%s\n" "${LIMIT_TO[@]}" | sort) \
		<(printf "%s\n" "${TO_CREATE[@]}" | sort) ) )

	TO_PUSH=( $(comm -12 <(printf "%s\n" "${LIMIT_TO[@]}" | sort) \
		<(printf "%s\n" "${TO_PUSH[@]}" | sort) ) )
fi

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
	git clone --bare \
		"${GH_REPOS[$repo]}" "$REPO_DIR/$repo"
done

echo DONE CLONING

for repo in "${TO_CREATE[@]}"; do
	echo Creating: "$repo"
	github_create_repo ${repo%.git}
	
	[ -z "${GH_REPOS[$repo]}" ] && echo No clone_URL? && continue

	TO_PUSH+=($repo)
done

echo DONE CREATING

for repo in "${TO_PUSH[@]}"; do
	git -C "$REPO_DIR/$repo" push --all "${GH_REPOS[$repo]}"
	git -C "$REPO_DIR/$repo" push --tags "${GH_REPOS[$repo]}"
done

echo
echo Done.
