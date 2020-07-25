#!/bin/bash

# gitwrapper.sh
#
# A wrapper for the 'git upload-pack' command
# to automatically create repositories if they are
# pushed to
#
# Set command="" in .ssh/authorized_keys:
#
#	command="/path/to/wrapper.sh myrepos" ssh-rsa ... user@example
#

function perror() {
	>&2 echo "$@"
}

# 1: exit code
function usage() {
	>&2 cat << EOF
$(basename $0) [options]

Options:
	-r <DIR>	Allow pull from DIR
	-w <DIR>	Allow push to DIR
	-a <DIR>	Allow push/pull from/to DIR
	-i		Allow inetractive Login
EOF
	exit $1
}

# checks, if this instance has access rights to git repo and
# for a valid path and repo name: 'folder/name.git'. paths containing '..'
# will allways fail.
# 1: path 2: w/r
function has_access() {
	local array=()
	[ "$2" = "w" ] && array=("${WRITING[@]}")
	[ "$2" = "r" ] && array=("${READING[@]}")

	readonly path_regex='^\s*/.*$|\.\.'
	if [[ "$1" =~ $path_regex ]]; then
		perror "Invalid file name."
		return 1
	fi

	readonly reponame_regex='^\w+\.git$'
	if [[ ! "$(basename "$1")" =~ $reponame_regex ]]; then
		perror "Invalid repository"
		return 1
	fi

	for dir in "${array[@]}"; do
		[ "$(dirname "$1")" = "$dir" ] && return 0
	done

	perror Invalid repository2
	return 1
}

unset INTERACTIVE READING WRITING
READING=()
WRITING=()

while getopts "r:w:a:i" options; do
	case "$options" in
		i)
			INTERACTIVE="yes";;
		r)
			READING+=( "$OPTARG" );;
		w)
			WRITING+=( "$OPTARG" );;
		a)
			WRITING+=( "$OPTARG" )
			READING+=( "$OPTARG" );;
		:)
			perror "-$OPTARG requires argument"
			usage 1;;
		*)
			perror "Unknown option $options"
			usage 1;;
	esac
done

if [ -z "$SSH_ORIGINAL_COMMAND" ]; then
	[ "$INTERACTIVE" = "yes" ] && bash
	exit $?
fi

read direction repo_path < <( echo "$SSH_ORIGINAL_COMMAND" | sed -n 's/^git[ -]\(receive\|upload\)-pack \(.*\)$/\1 \2/p' | tr -d "'" )
[ -z "$repo_path" ] && exit 1

if [ "$direction" = "receive" ]; then
	if ! has_access "$repo_path" "w"; then
		perror "An error occured: No such file or directory."
		exit 1
	fi

	[ ! -e "$repo_path" ] && git init --bare "$repo_path" > /dev/null

	git-receive-pack "$repo_path"
elif [ "$direction" = "upload" ]; then
	if ! has_access "$repo_path" "r"; then
		perror "An error occured: No such file or directory."
		exit 1
	fi

	[ -e "$repo_path" ] && git-upload-pack "$repo_path" || git-upload-pack empty.git
fi
exit $?
