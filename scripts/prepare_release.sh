#!/bin/bash

set -e

TOPDIR="$(git rev-parse --show-toplevel)"
BASEBRANCH="main"
BRANCHPREFIX="release"
UPDATE=0

generate_default_xml() {
	if [ -n "$URI" ]; then
		echo "Copying default.xml ..."
		curl "$URI" -o $TOPDIR/default.xml
		SOURCE=$URI
	else
		echo "Generating default.xml ..."
		pushd $WORKDIR > /dev/null
		repo init -q -b $BASEBRANCH -u $TOPDIR -g all,ofdpa-gitlab
		repo sync
		repo manifest --revision-as-HEAD -o $TOPDIR/default.xml
		popd > /dev/null
		SOURCE="current $BASEBRANCH branch"
	fi

	if [ "$UPDATE" -eq 1 ]; then
		MSG="default.xml: update release revisions

Upate release revisions in default.xml based on $SOURCE."
	else
		MSG="default.xml: set release revisions

Set release revisions in default.xml based on $SOURCE."
	fi

	git commit -s -m "$MSG" default.xml
}

# Check that the top commits for OF-DPA and ofdpa-grpc recipes are identical
# between open and closed repositories by comparing the subjects.
#
# If there is a difference, we must have forgotten to push an update to the
# open repository.
sanity_check_meta-ofdpa() {
	echo "Ensuring public and closed meta-ofdpa are in sync ..."
	local abort=0
	pushd $WORKDIR > /dev/null
	repo init -q -b $RELEASE_BRANCH -u $TOPDIR -g all,ofdpa-gitlab
	repo sync

	pushd poky/meta-ofdpa > /dev/null
	OFDPA_OPEN_TOP="$(git log --no-merges --pretty='format:%s' -1 recipes-ofpda/ofdpa/ofdpa_*.bb)"
	OFDPA_GRPC_OPEN_TOP="$(git log --no-merges --pretty='format:%s' -1 recipes-extended/ofdpa-grpc/ofdpa-grpc_*.bb)"
	popd > /dev/null
	pushd poky/meta-ofdpa-closed > /dev/null
	OFDPA_CLOSED_TOP="$(git log --no-merges --pretty='format:%s' -1 recipes-ofpda/ofdpa/ofdpa_*.bb)"
	OFDPA_GRPC_CLOSED_TOP="$(git log --no-merges --pretty='format:%s' -1 recipes-extended/ofdpa-grpc/ofdpa-grpc_*.bb)"
	popd > /dev/null

	popd > /dev/null

	if [ "$OFDPA_OPEN_TOP" != "$OFDPA_CLOSED_TOP" ]; then
		echo "meta-ofdpa [gitlab] OF-DPA recipe has unpublished changes!" >&2

		echo " meta-ofdpa [github] OF-DPA recipe HEAD: $OFDPA_OPEN_TOP" >&2
		echo " meta-ofdpa [gitlab] OF-DPA recipe HEAD: $OFDPA_CLOSED_TOP" >&2
		abort=1
	fi

	if [ "$OFDPA_GRPC_OPEN_TOP" != "$OFDPA_GRPC_CLOSED_TOP" ]; then
		echo "meta-ofdpa [gitlab] ofdpa-grpc recipe has unpublished changes!" >&2

		echo " meta-ofdpa [github] ofdpa-grpc recipe HEAD: $OFDPA_GRPC_OPEN_TOP" >&2
		echo " meta-ofdpa [gitlab] ofdpa-grpc recipe HEAD: $OFDPA_GRPC_CLOSED_TOP" >&2
		abort=1
	fi

	if [ "$abort" = "1" ]; then
		exit 1
	fi
}

generate_changelog() {
	echo "Generating changelog (this may take a while) ..."

	$TOPDIR/scripts/changelog.sh -f -w $WORKDIR -n $NEW -i meta-ofdpa-closed $OLD "$RELEASE_BRANCH" > changelog.txt
	git add changelog.txt

	if [ "$UPDATE" -eq 1 ]; then
		MSG="update changelog.txt"
	else
		MSG="add changelog.txt"
	fi

	git commit -s -m "$MSG" changelog.txt
}

set_feed_uri_prefix() {
	echo "Setting FEEDURIPREFIX to release value ..."
	echo 'FEEDURIPREFIX = "pub/onie/${MACHINE}/packages-v${DISTRO_VERSION}"' >> conf/local.conf.sample
	git commit -s -m "conf: set release FEEDURIPREFIX

Set the FEEDURIPREFIX to the release path." conf/local.conf.sample
}

update_default_xml() {
	echo "Updating default.xml to point commit with the changelog.txt ..."
	# update default.xml so that the bisdn-linux checkout will be include
	# the changelog.txt and release FEEDURIPREFIX

	HEAD_COMMIT="$(git rev-parse HEAD)"
	xmlstarlet edit --inplace \
	       --update "/manifest/project[@name='bisdn/bisdn-linux.git']/@upstream" --value "$RELEASE_BRANCH" \
	       --update "/manifest/project[@name='bisdn/bisdn-linux.git']/@dest-branch" --value "$RELEASE_BRANCH" \
	       --update "/manifest/project[@name='bisdn/bisdn-linux.git']/@revision" --value "$HEAD_COMMIT" \
	       default.xml

	if [ "$UPDATE" -eq 1 ]; then
		MSG="default.xml: update build-bisdn-linux to new revision

Update build-bisdn-linux to include the updated changelog.txt.
"
	else
		MSG="default.xml: switch build-bisdn-linux to release branch

Update build-bisdn-linux to include the generated changelog.txt and release
FEEDURIPREFIX.
"
	fi
	git commit -s -m "$MSG" default.xml
}

print_help() {
	echo "Prepare or update a release branch with fixed revisions and release configuration"
	echo ""
	echo "Prepares a release branch named release/<new_version> with the configuration"
	echo "updated for a release, a default.xml with fixed revisions and a changelog.txt"
	echo "based on the passed <old_version>."
	echo "Revisions taken either from current $BASEBRANCH or a default.xml passed via URI"
	echo "argument."
	echo "If the release branch already exists, update default.xml and changelog.txt only."
	echo ""
	echo "Usage:"
	echo "$0 <old_version> <new_version> [URI]"
	exit 1
}

OLD=$1
NEW=$2
URI=$3

if [ -z "$OLD" -o -z "$NEW" ]; then
	print_help
fi

REQUIRED_BINARIES="curl git repo xmlstarlet"
FAILED=0

for binary in $REQUIRED_BINARIES; do
	if ! command -v $binary > /dev/null; then
		echo "ERROR: '$binary' was not found in path." >&2
		FAILED=1
	fi
done

if [ "$FAILED" != "0" ]; then
	echo "ERROR: Some required programs are not available. Please install and try again." >&2
	exit 1
fi

RELEASE_BRANCH="$BRANCHPREFIX/$NEW"
WORKDIR=$(mktemp -d)
# make sure we delete it again
trap "rm -rf $WORKDIR" EXIT

echo "Preparing branch $RELEASE_BRANCH"

pushd $TOPDIR

# make sure we are up to date
git fetch
# if $OLD is a branch, make sure $OLD exists and is up to date
if ! git rev-parse --verify --quiet --tags "refs/tags/$OLD" > /dev/null; then
	git branch -f $OLD origin/$OLD
fi

if git rev-parse --verify --quiet "refs/heads/$RELEASE_BRANCH" > /dev/null; then
	# branch already exists, so only update it
	UPDATE=1
	git checkout "$RELEASE_BRANCH"
else
	# this is a new branch, so create it and set it to release
	git switch -c "$RELEASE_BRANCH" $BASEBRANCH
	set_feed_uri_prefix
fi

generate_default_xml
sanity_check_meta-ofdpa
generate_changelog
update_default_xml

popd

echo "Release branch successfully prepared/updated as $RELEASE_BRANCH

Please review and directly push if acceptable.

WARNING: Do *NOT* create a pull request, as pull requests will rewrite commits
when merged, breaking the bisdn-linux reference in default.xml.
"
