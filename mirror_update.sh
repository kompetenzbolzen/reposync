#!/bin/bash

# fetch mirrors

[ ! -d "$1" ] && exit 1

ROOTDIR=$(realpath "$1")

for dir in $ROOTDIR/*; do
	echo $dir
	git -C "$dir" fetch --all
done
