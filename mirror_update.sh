#!/bin/bash

# fetch mirrors

[ ! -d "$1" ] && exit 1

ROOTDIR=$(realpath "$1")

for dir in $(ls -d "$ROOTDIR/*.git/"); do
	echo $dir
	git -C "$dir" fetch --mirror
done
