#!/bin/bash

REALPATH=$(realpath $1)

[ ! -d "$REALPATH" ] && exit 1

for f in $REALPATH/*.git/description; do
	CONTENT=$(cat $f)
	[ "$CONTENT" = "Unnamed repository; edit this file 'description' to name the repository." ] && echo > $f
done

