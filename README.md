# BISDN Linux build system

This repository holds the main repo manifest for setting up the build system
for BISDN Linux, based on Yocto.

## Prerequisites

* Disk space
We recommend a minimum of 150GB free disk space for building a single full
image. The build process usually requires ~70GB of disk space.

* repo tool

Many distros include repo, so you might be able to install from there.

```bash
# Debian/Ubuntu.
sudo apt-get install repo
```

```bash
# Gentoo.
sudo emerge dev-vcs/repo
```

You can install it manually as well as it's a single script.

```bash
# install
mkdir ~/bin
PATH=~/bin:$PATH
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
```

See [the official documentation](https://source.android.com/source/using-repo.html) for further details.

* install your OS specific [build essentials for Yocto](https://docs.yoctoproject.org/3.1.7/ref-manual/ref-system-requirements.html)

Some Yocto packages may require additional utilities to be present on the
build host.

## Bootstrap build system

```bash
# init repo
mkdir -p ~/workspace/poky-bisdn-linux
cd !$
repo init -b BRANCHNAME -u git@github.com:bisdn/bisdn-linux.git

# sync repos
repo sync

# init build system
. poky/oe-init-build-env poky/build-bisdn-linux/
```

## Configure target machine

Edit conf/local.conf and set `MACHINE` to your desired target.

## Build image

Chose one of the available image types to build

* `minimal`: bare minimum of packages for booting the system. Does not include any
  closed source packages outside of required firmware files.

* `full`: include the full BISDN Linux system, including baseboxd and OF-DPA.

```bash
# build the yocto artifacts
bitbake <minimal|full>
```

The finished image can be found at `/tmp/deploy/${MACHINE}/images/${MACHINE}/onie-bisdn-full-${MACHINE}.bin`.

## Install image

Please refer to our [BISDN Linux docs](https://docs.bisdn.de/getting_started/install_bisdn_linux.html) on how to install the resulting image.
