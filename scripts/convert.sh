#!/bin/bash

TOPDIR="$(git rev-parse --show-toplevel)"

declare -A REPOS

read_lockfile() {
	REPOS["meta-bisdn-linux"]=$(cat $1 | yq -r '.overrides.repos."meta-bisdn-linux".commit')
	REPOS["meta-cloud-services"]=$(cat $1 | yq -r '.overrides.repos."meta-cloud-services".commit')
	REPOS["meta-ofdpa"]=$(cat $1 | yq -r '.overrides.repos."meta-ofdpa".commit')
	REPOS["meta-ofdpa-closed"]=$(cat $1 | yq -r '.overrides.repos."meta-ofdpa-closed".commit')
	REPOS["meta-open-network-linux"]=$(cat $1 | yq -r '.overrides.repos."meta-open-network-linux".commit')
	REPOS["meta-openembedded"]=$(cat $1 | yq -r '.overrides.repos."meta-openembedded".commit')
	REPOS["meta-virtualization"]=$(cat $1 | yq -r '.overrides.repos."meta-virtualization".commit')
	REPOS["poky"]=$(cat $1 | yq -r '.overrides.repos."poky".commit')
}

write_lockfile() {
	VERSION=$(cat ${TOPDIR}/bisdn-linux.yaml | yq -r '.header.version')
	cat >$1 << EOF
header:
    version: ${VERSION}
overrides:
    repos:
        meta-bisdn-linux:
            commit: ${REPOS["meta-bisdn-linux"]}
        meta-cloud-services:
            commit: ${REPOS["meta-cloud-services"]}
        meta-ofdpa:
            commit: ${REPOS["meta-ofdpa"]}
        meta-ofdpa-closed:
            commit: ${REPOS["meta-ofdpa-closed"]}
        meta-open-network-linux:
            commit: ${REPOS["meta-open-network-linux"]}
        meta-openembedded:
            commit: ${REPOS["meta-openembedded"]}
        meta-virtualization:
            commit: ${REPOS["meta-virtualization"]}
        poky:
            commit: ${REPOS["poky"]}
EOF
}

read_manifest() {
	REPOS["bisdn-linux"]=$(xmlstarlet select -t -v  "/manifest/project[@name='bisdn/bisdn-linux.git']/@revision" $1)
	REPOS["meta-bisdn-linux"]=$(xmlstarlet select -t -v  "/manifest/project[@name='bisdn/meta-bisdn-linux.git']/@revision" $1)
	REPOS["meta-cloud-services"]=$(xmlstarlet select -t -v  "/manifest/project[@name='meta-cloud-services']/@revision" $1)
	REPOS["meta-ofdpa"]=$(xmlstarlet select -t -v  "/manifest/project[@name='bisdn/meta-ofdpa.git']/@revision" $1)
	REPOS["meta-ofdpa-closed"]=$(xmlstarlet select -t -v  "/manifest/project[@name='yocto-meta-layers/meta-ofdpa.git']/@revision" $1)
	REPOS["meta-open-network-linux"]=$(xmlstarlet select -t -v  "/manifest/project[@name='bisdn/meta-open-network-linux.git']/@revision" $1)
	REPOS["meta-openembedded"]=$(xmlstarlet select -t -v  "/manifest/project[@name='meta-openembedded']/@revision" $1)
	REPOS["meta-virtualization"]=$(xmlstarlet select -t -v  "/manifest/project[@name='meta-virtualization']/@revision" $1)
	REPOS["poky"]=$(xmlstarlet select -t -v  "/manifest/project[@name='poky']/@revision" $1)
}

write_manifest() {
	# KAS does not reference this repository, so take the HEAD revision
	if [ -z "${REPOS["bisdn-linux"]}" ]; then
		REPOS["bisdn-linux"]="$(git rev-parse HEAD)"
	fi

	if [ "$1" == "default.xml" ]; then
		INPLACE="--inplace"
		OUT_FILE=""
	else
		INPLACE=""
		OUT_FILE=$1
	fi

	xmlstarlet edit ${INPLACE} \
	       --update "/manifest/project[@name='bisdn/bisdn-linux.git']/@revision" --value "${REPOS["bisdn-linux"]}" \
	       --update "/manifest/project[@name='bisdn/meta-bisdn-linux.git']/@revision" --value "${REPOS["meta-bisdn-linux"]}" \
	       --update "/manifest/project[@name='meta-cloud-services']/@revision" --value "${REPOS["meta-cloud-services"]}" \
	       --update "/manifest/project[@name='bisdn/meta-ofdpa.git']/@revision" --value "${REPOS["meta-ofdpa"]}" \
	       --update "/manifest/project[@name='yocto-meta-layers/meta-ofdpa.git']/@revision" --value "${REPOS["meta-ofdpa-closed"]}" \
	       --update "/manifest/project[@name='bisdn/meta-open-network-linux.git']/@revision" --value "${REPOS["meta-open-network-linux"]}" \
	       --update "/manifest/project[@name='meta-openembedded']/@revision" --value "${REPOS["meta-openembedded"]}" \
	       --update "/manifest/project[@name='meta-virtualization']/@revision" --value "${REPOS["meta-virtualization"]}" \
	       --update "/manifest/project[@name='poky']/@revision" --value "${REPOS["poky"]}" \
	       "${TOPDIR}/default.xml" ${OUT_FILE}
}

case "$1" in
	*.yml)
		read_lockfile $1
		;;
	*.xml)
		read_manifest $1
		;;
	*)
		exit 1
		;;
esac

case "$2" in
	*.yml)
		write_lockfile $2
		;;
	*.xml)
		write_manifest $2
		;;
	*)
		exit 1
		;;
esac
