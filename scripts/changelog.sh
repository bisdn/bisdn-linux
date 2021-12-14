#!/bin/bash
#
# changelog.sh - Generate a list of new commits between two releases
# 
# SPDX-License-Identifier: MPL-2.0
#
# (C) 2021 BISDN GmbH

set -e

ONELINE_FORMAT_COMMIT='%C(auto)%h %s'
ONELINE_FORMAT='%C(auto)%s'

while getopts 'cehp:g:vw:' c
do
	case "$c" in
	c)
		PRINT_COMMITS=1
		;;
	e)
		PRINT_EMPTY=1
		;;
	g)
		SINGLE_REPO=1
		GIT_REPO=$OPTARG
		;;
	h)
		PRINT_HELP=1
		;;
	p)
		PREFIX=$OPTARG
		;;
	v)
		PRINT_VERSIONS=1
		;;
	w)
		WORKDIR=$OPTARG
		;;
	esac
done

shift $((OPTIND-1))
OLD=$1
NEW=$2

# $1 list of packages in the image
# $2 packages available and their versions
collect_package_versions() {
	local package_list pkg_name pkg_version depends_file
	declare -n packages=$1
	declare -n versions=$2

	sed -i 's|^TMPDIR = .*|TMPDIR = "${TOPDIR}/tmp"|' conf/local.conf.sample
	sed -i 's|^DL_DIR ?= .*|DL_DIR = "${TOPDIR}/dl"|' conf/local.conf.sample
	sed -i 's|^SSTATE_DIR ?= .*|SSTATE_DIR = "${TOPDIR}/sstate-cache"|' conf/local.conf.sample
	source ../oe-init-build-env . > /dev/null
	git checkout conf/local.conf.sample
	bitbake -g full >/dev/null

	# This is a list of recipe names, not (sub-)packages, but unless we
	# also want to build an image, this is the closest we can get. 
	packages=$(grep -v -e '-native' pn-buildlist)
	oIFS=$IFS
	IFS="
"
	package_list=$(bitbake -s full)
	for package in $package_list; do
		pkg_name=$(echo $package | awk '{ print $1}')
		pkg_version=$(echo $package | awk -F: '{print $2}')
		versions[$pkg_name]=$pkg_version
	done
	IFS=$oIFS
}

[ -n "$PRINT_HELP" -o -z "$OLD" -o -z "$NEW" ] && {
	echo "Generate a full release changelog:"
	echo "Usage: $0 [<options>] <oldversion> <newversion>"
	echo "Generate a changelog for two branches in a single git repository"
	echo "Usage: $0 [<options>] -g <uri> <oldversion> <newversion>"
	echo "Options:"
	echo "  -c		print commit hashes"
	echo "  -e		print repos without changes"
	echo "  -g		use a single git repo instead of a repo source"
	echo "  -h		print help"
	echo "  -p <prefix>	prefix all changelog entries with <prefix>"
	echo "  -v		print a list of updated packages and their versions"
	echo "  -w <dir>	use <dir> as repo work dir (warning: will discard any changes!)"
	exit 1
}

which repo &>/dev/null || {
	echo "ERROR: no working repo utility found."
	exit 1
}

declare -A old_revs
declare -A new_revs
declare -A repos
declare -A repo_paths
declare -A old_versions
declare -A new_versions

# use WORKDIR if defined, else create a temporary directory
if [ -z "$WORKDIR" ]; then
	tmp_dir=$(mktemp -d)
	WORKDIR=$tmp_dir
fi


pushd $WORKDIR >/dev/null
if [ -z "$SINGLE_REPO" ]; then
	repo init -q -b $OLD  -u https://github.com/bisdn/bisdn-linux.git >/dev/null
	repo sync -q >/dev/null

	dirs=$(repo list -p)
	for dir in $dirs; do
		pushd $dir >/dev/null
		REV=$(git rev-parse HEAD)
		popd > /dev/null
		layer=$(basename $dir)
		old_revs[$layer]=$REV
		repos[$layer]=1
	done

	if [ -n "$PRINT_VERSIONS" ]; then
		pushd $(repo list -p | grep 'build-') >/dev/null
		collect_package_versions old_packages old_versions
		popd >/dev/null
	fi
	repo init -q -b $NEW >/dev/null
	repo sync -q --force-sync >/dev/null

	dirs=$(repo list -p)
	for dir in $dirs; do
		pushd $dir >/dev/null
		REV=$(git rev-parse HEAD)
		popd > /dev/null
		layer=$(basename $dir)
		new_revs[$layer]=$REV
		repos[$layer]=1
		repo_paths[$layer]=$dir
	done

	if [ -n "$PRINT_VERSIONS" ]; then
		pushd $(repo list -p | grep 'build-') >/dev/null
		collect_package_versions new_packages new_versions
		popd >/dev/null
	fi

	repo_dirs=$(echo ${!repos[@]} | tr ' ' '\n' | sort | tr '\n' ' ')
else
	git clone ${GIT_REPO} git-repo >/dev/null
	repos["git-repo"]=1
	repo_paths["git-repo"]="git-repo"
	pushd git-repo >/dev/null
	git checkout $OLD >/dev/null
	old_revs["git-repo"]=$(git rev-parse HEAD)
	git checkout $NEW >/dev/null
	new_revs["git-repo"]=$(git rev-parse HEAD)
	popd > /dev/null
	repo_dirs="git-repo"
fi

if [ -n "$PRINT_VERSIONS" ]; then
	packages=$(echo $old_packages $new_packages | tr '"' ' ' | tr ' ' '\n' | sort -u | tr '\n' ' ')
	echo -e "\nUpdated packages:"
	for package in $packages; do
		old_version=$(echo ${old_versions[$package]})
		new_version=$(echo ${new_versions[$package]})
		[ "$old_version" = "$new_version" ] && continue
		if [ -z "$old_version" ]; then
			bump="NEW"
		elif [ -z "$new_version" ]; then
			bump="REMOVED"
		else
			bump="$old_version => $new_version"
		fi

		echo "$package ($bump)"
	done
fi

echo -e "\nChanges between $OLD and $NEW:\n"

for dir in $repo_dirs; do
	rev_old=${old_revs[$dir]}
	rev_new=${new_revs[$dir]}

	if [ -n "$rev_old" -a -n "$rev_new" ]; then
		pushd ${repo_paths[$dir]} >/dev/null

		if ! git cat-file -t $rev_old >/dev/null; then
			# repo changed, and revision does not exist in new repo
			echo "$dir: $OLD's revision not found in git repo, skipping ..." >&2
			popd >/dev/null
			continue
		fi

		MERGE_BASE=$(git merge-base $rev_old $rev_new)
		if [ "$MERGE_BASE" != "$rev_old" ]; then
			# get a list of commits, then iterate over them and
			# remove any commits with the same subject in both
			# branches to remove duplicates.

			changes_old=$(git log --format="$ONELINE_FORMAT_COMMIT" --no-merges $MERGE_BASE..$rev_old)
			changes_new=$(git log --format="$ONELINE_FORMAT_COMMIT" --no-merges $MERGE_BASE..$rev_new)
			changes=""
			oIFS=$IFS
			IFS="
"
			for change in $changes_new; do
				TEXT=${change#* }
				SKIP=
				for oldchange in $changes_old; do
					OLD_TEXT=${oldchange#* }
					if [ "$TEXT" = "$OLD_TEXT" ]; then
						SKIP=1
						break
					fi
				done
				[ -n "$SKIP" ] && continue

				[ -n "$changes" ] && changes="$changes
"
				 [ -n "$PRINT_COMMITS" ] && TEXT=$change
				changes="${changes}${PREFIX}${TEXT}"
			done
			IFS=$oIFS
		else
			if [ -n "$PRINT_COMMITS" ]; then
				FORMAT="$ONELINE_FORMAT_COMMIT"
			else
				FORMAT="$ONELINE_FORMAT"
			fi

			changes=$(git log --format="$PREFIX$FORMAT" --no-merges $rev_old..$rev_new)
		fi
		popd >/dev/null
		if [ -n "$changes" ]; then
			echo "$dir:"
			echo -e "$changes\n"
		elif [ -n "$PRINT_EMPTY" ]; then
			echo "$dir:"
			echo -e "(no changes)\n"
		fi
	elif [ -z "$rev_old" ]; then
		echo -e "$dir (NEW)\n"
	else
		echo -e "$dir (REMOVED)\n"
	fi
done
popd >/dev/null

# remove the temporary directory again
[ -n "$tmp_dir" ] && rm -rf $tmp_dir
