#!/usr/bin/env bash
# script for calculating the newest commit date of all sub repositories used,
# output as a unix timestamp to be timezone/dateformat agnostic.

PATHS="$(repo list -p -f)"

NEWEST=0

for path in $PATHS; do
	COMMITDATE=$(git -c log.showSignature=false --git-dir "$path/.git" log -1 --pretty=%ct)
	if [ "$COMMITDATE" -gt "$NEWEST" ]; then
		NEWEST=$COMMITDATE
	fi
done

echo "$NEWEST"
