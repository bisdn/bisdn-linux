#!/bin/bash
#
# changelog.sh - Generate a list of new commits between two releases
#
#
# SPDX-License-Identifier: MPL-2.0
#
# (C) 2021-2023 BISDN GmbH

set -e

TOPDIR="$(git rev-parse --show-toplevel)"

ONELINE_FORMAT_COMMIT='%C(auto)%h %s'
ONELINE_FORMAT='%C(auto)%s'

IGNORED_LAYERS=""

while getopts 'cefhi:n:o:p:vw:' c
do
	case "$c" in
	c)
		PRINT_COMMITS=1
		;;
	e)
		PRINT_EMPTY=1
		;;
	f)
		PRINT_CVE_FIXES=1
		;;
	h)
		PRINT_HELP=1
		;;
	i)
		IGNORED_LAYERS=$OPTARG
		;;
	n)
		NEW_VERSION=$OPTARG
		;;
	o)
		OLD_VERSION=$OPTARG
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
# $3 list of open CVE issues
collect_bitbake_info() {
	local package_list pkg_name pkg_version depends_file cve_file cve_list
	local template_dir
	declare -n packages=$1
	declare -n versions=$2
	declare -n cve_issues=$3

	# BB_ENV_EXTRAWHITE was renamed to BB_ENV_PASSTHROUGH_ADDITIONS and
	# bitbake will error out if the old one exists in the environment, so
	# make sure that neither is set
	unset BB_ENV_EXTRAWHITE
	unset BB_ENV_PASSTHROUGH_ADDITIONS

	if [ ! -f conf/local.conf.sample ]; then
		template_dir=../meta-bisdn-linux/conf/templates/bisdn-linux
	else
		# older version, not using TEMPLATECONF yet
		template_dir=conf
	fi

	rm -f conf/local.conf
	rm -f conf/bblayers.conf

	sed -i 's|^TMPDIR = .*|TMPDIR = "${TOPDIR}/tmp"|' $template_dir/local.conf.sample
	sed -i 's|^DL_DIR ?= .*|DL_DIR = "${TOPDIR}/dl"|' $template_dir/local.conf.sample
	sed -i 's|^SSTATE_DIR ?= .*|SSTATE_DIR = "${TOPDIR}/sstate-cache"|' $template_dir/local.conf.sample
	if [ -n "$PRINT_CVE_FIXES" ]; then
		echo 'INHERIT += "cve-check"' >> $template_dir/local.conf.sample
	fi
	TEMPLATECONF="meta-bisdn-linux/conf/templates/bisdn-linux" source ../oe-init-build-env . >&2

	pushd $template_dir > /dev/null
	git checkout local.conf.sample >&2
	popd > /dev/null

	bitbake -g full >&2
	if [ -n "$PRINT_CVE_FIXES" ]; then
		bitbake --runall cve_check full >&2
		cve_file="$(pwd)/tmp/log/cve/cve-summary.json"
	fi

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
		if [ -n "$PRINT_CVE_FIXES" ]; then
			# JSON format example:
			# {
			#   "version": "1",
			#   "package": [
			#     {
			#       "name": "python3-cryptography",
			#       "layer": "meta",
			#       "version": "36.0.2",
			#       "products": [
			#         {
			#           "product": "cryptography",
			#           "cvesInRecord": "No"
			#         }
			#       ],
			#       "issue": [
			#         {
			#           "id": "CVE-2023-23931",
			#           "summary": "(omitted for readability)",
			#           "scorev2": "0.0",
			#           "scorev3": "6.5",
			#           "vector": "NETWORK",
			#           "status": "Patched",
			#           "link": "https://nvd.nist.gov/vuln/detail/CVE-2023-23931"
			#         }
			#       ]
			#     }
			#   ]
			# }
			# collect all issue ids with status 'Unpatched' for this package:
			cve_list=$(jq -r '.package[] | select (.name == "'${pkg_name}'") | .issue[] | select ( .status == "Unpatched" ) | { id } | join(" ")' $cve_file)
			cve_issues[$pkg_name]="$cve_list"
		fi
	done
	IFS=$oIFS

	# reset to initial state
	unset BB_ENV_EXTRAWHITE
	unset BB_ENV_PASSTHROUGH_ADDITIONS
	rm -f conf/local.conf
	rm -f conf/bblayers.conf
}

[ -n "$PRINT_HELP" -o -z "$OLD" -o -z "$NEW" ] && {
	echo "Generate a full release changelog for BISDN Linux and write it to STDOUT"
	echo ""
	echo "Generates a list of new commits between two versions for all (default) projects"
	echo "defined in the default.xml, separated by project name."
	echo ""
	echo "Usage: $0 [<options>] <oldbranch|oldtag> <newbranch|newtag>"
	echo "  e.g. $0 v4.8.0 v4.9.0"
	echo "Options:"
	echo "  -c		print commit hashes"
	echo "  -e		print repos without changes"
	echo "  -f		print a list of fixed CVEs (may take a long time)"
	echo "  -h		print this help"
	echo "  -i		comma separated list of layers to ignore"
	echo "  -n <new>	set the name of the new version (default: <newbranch|newtag>)"
	echo "  -o <new>	set the name of the old version (default: <oldbranch|oldtag>)"
	echo "  -p <prefix>	prefix all changelog entries with <prefix> (e.g. ' - ')"
	echo "  -v		also include a list of updated packages and their version changes"
	echo "  -w <dir>	use <dir> as repo work dir (warning: will discard any changes!)"
	exit 1
}

which repo &> /dev/null || {
	echo "ERROR: no working repo utility found." >&2
	exit 1
}

declare -A old_revs
declare -A new_revs
declare -A repos
declare -A repo_paths
declare -A old_versions
declare -A new_versions
declare -A old_open_cves
declare -A new_open_cves

# use WORKDIR if defined, else create a temporary directory
if [ -z "$WORKDIR" ]; then
	WORKDIR=$(mktemp -d)
	# make sure we delete it again when we are finished
	trap "rm -rf $WORKDIR" EXIT
fi

pushd "$WORKDIR" > /dev/null

# repo requires tags to be passed as "refs/tags/<name>", anything else will be
# be treated as a branch and repo tries to checkout refs/heads/<name>, which
# will fail for tags. So check if $OLD is a tag and use the full path.
TAG="$(git ls-remote --tags $TOPDIR $OLD | awk '{print $2}')"
repo init -q -b ${TAG:-${OLD}}  -u $TOPDIR > /dev/null
repo sync -q > /dev/null

dirs=$(repo list -p)
for dir in $dirs; do
	pushd $dir > /dev/null
	REV=$(git rev-parse HEAD)
	popd > /dev/null
	layer=$(basename $dir)
	if echo $IGNORED_LAYERS | grep -q -P "(?<![\w-])$layer(?![\w-])"; then
		continue
	fi
	old_revs[$layer]=$REV
	repos[$layer]=1
done

if [ -n "$PRINT_VERSIONS" ] || [ -n "$PRINT_CVE_FIXES" ]; then
	pushd $(repo list -p | grep 'build-') > /dev/null
	collect_bitbake_info old_packages old_versions old_open_cves
	popd > /dev/null
fi

# As with $OLD, we need to use the full path if $NEW is a tag.
TAG="$(git ls-remote --tags $TOPDIR $NEW | awk '{print $2}')"
repo init -q -b ${TAG:-${NEW}} > /dev/null
repo sync -q --force-sync > /dev/null

dirs=$(repo list -p)
for dir in $dirs; do
	pushd "$dir" > /dev/null
	REV=$(git rev-parse HEAD)
	popd > /dev/null
	layer=$(basename "$dir")

	# we cannot use -F, as -F considers dashes as a word delimiter, but
	# layernames use them (e.g. meta-cloud-services).
	# So use a handcrafted regex that only considers whitespaces.
	if echo $IGNORED_LAYERS | grep -q -P "(?<![\w-])$layer(?![\w-])"; then
		continue
	fi
	new_revs[$layer]=$REV
	repos[$layer]=1
	repo_paths[$layer]=$dir
done

if [ -n "$PRINT_VERSIONS" ] || [ -n "$PRINT_CVE_FIXES" ]; then
	pushd $(repo list -p | grep 'build-') > /dev/null
	collect_bitbake_info new_packages new_versions new_open_cves
	popd > /dev/null
fi

# meta-switch was renamed to meta-bisdn-linux, so treat meta-switch as an
# old version of meta-bisdn-linux and pretend meta-switch does not exist.
if [ -n "${repos['meta-switch']}" ] && [ -n "${repos['meta-bisdn-linux']}" ]; then
	old_revs["meta-bisdn-linux"]=${old_revs["meta-switch"]}
	unset -v 'repos["meta-switch"]'
fi

repo_dirs=$(echo ${!repos[@]} | tr ' ' '\n' | sort | tr '\n' ' ')

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

if [ -n "$PRINT_CVE_FIXES" ]; then
	packages=$(echo $old_packages $new_packages | tr '"' ' ' | tr ' ' '\n' | sort -u | tr '\n' ' ')
	echo -e "\nFixed CVEs:"
	for package in $packages; do
		old_cves=$(echo ${old_open_cves[$package]})
		new_cves=$(echo ${new_open_cves[$package]})
		old_version=$(echo ${old_versions[$package]})
		new_version=$(echo ${new_versions[$package]})

		if [ -z "$old_version" ] || [ -z "$new_version" ]; then
			# we don't care about CVEs in deleted packages
			# there are no CVE changes in new packages
			continue
		fi

		fixed_cves=$(comm -23 <(echo "$old_cves") <(echo "$new_cves"))

		if [ -n "$fixed_cves" ]; then
			echo "$package:"
			echo "  $fixed_cves"
			echo ""
		fi
	done
fi

echo -e "Changes between ${OLD_VERSION:-${OLD}} and ${NEW_VERSION:-${NEW}}:\n"

for dir in $repo_dirs; do
	rev_old=${old_revs[$dir]}
	rev_new=${new_revs[$dir]}

	if [ -n "$rev_old" -a -n "$rev_new" ]; then
		pushd ${repo_paths[$dir]} > /dev/null

		if ! git cat-file -t $rev_old > /dev/null; then
			# repo changed, and revision does not exist in new repo
			echo "$dir: $OLD's revision not found in git repo, skipping ..." >&2
			popd > /dev/null
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
		popd > /dev/null
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
popd > /dev/null
