#!/bin/bash
BRANCH="$(git symbolic-ref --short HEAD)"
TOPDIR=$(git rev-parse --show-toplevel)
NOTES=$1

if [ -z "$NOTES" ]; then
	echo "Usage: $0 <file to upload>"
	exit 1
fi

if [ ! -f "$NOTES" ]; then
	echo "no such file: $NOTES"
	exit 1
fi

case "$BRANCH" in
	v[1-9]*)
		;;
	*)
		echo "current branch ($BRANCH) is not a release branch!"
		exit 1
		;;
esac

PLATFORMS="$(awk '/#MACHINE \?=/{ print $3 }' ${TOPDIR}/conf/local.conf.sample | tr -d '"')"

for platform in $PLATFORMS; do
	aws s3 cp $NOTES s3://repo.bisdn.de/pub/onie/$platform/onie-bisdn-$platform-$BRANCH-releasenotes.txt
done
