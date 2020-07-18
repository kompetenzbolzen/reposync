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

[ -z "$1" ] && >&2 echo Invalid configuration in authorized_keys && exit 1
ALLOWED_REPODIR="$1"

if [ -z "$SSH_ORIGINAL_COMMAND" ]; then
	bash
	exit $?
fi

repo_path=$(sed -n 's/^git upload-pack \(.*\)$/\1/p' <<< "$SSH_ORIGINAL_COMMAND")
if [ ! -z "$repo_path" ]; then
	if grep -q '\.\.' <<< "$repo_path"; then
		>&2 echo Invalid file name.
		exit 1
	fi

	reponame_regex='^\w+\.git$'
	if [ "$(dirname "$repo_path")" != "$ALLOWED_REPODIR" ] || \
	   [[ ! "$(basename "$repo_path")" =~ $reponame_regex ]]; then
		>&2 echo Invalid repository
		exit 1
	fi

	[ ! -e "$repo_path" ] && git init --bare "$repo_path"
fi

eval $SSH_ORIGINAL_COMMAND
