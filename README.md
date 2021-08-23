# BISDN Linux build system

This repository holds the main repo manifest for setting up the build system
for BISDN Linux, based on Yocto.

The build process takes around 3-4 hours with 8 CPU cores and 8 GiB RAM. A single
build requires ~70 GiB of disk space. Adding additional CPU cores speeds up the
build time significally.

## Prerequisites

* Disk space and RAM

We recommend a minimum of 8 GiB RAM and 150 GiB free disk space for building a single full
image.

* repo tool

Some distros include [repo](https://android.googlesource.com/tools/repo), so
you might be able to install from there.

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

* BISDN-Linux specific build requirements

Additionally [libelf](https://directory.fsf.org/wiki/Libelf) with development headers and
[PyYAML](https://pyyaml.org/) are needed. On Ubuntu (20.04 and newer) this can
be installed by running.

```bash
sudo apt-get install libelf-dev python-yaml
```

For information on installing these requirements on a different OS please visit
the respective project page.

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

## Configure target machine and cache directory

Edit conf/local.conf and set `MACHINE` to your desired target. Cached files and built artifacts
will be stored in `/tmp` by default. Change the variables `SSTATE_DIR`,
`TMPDIR`, `DL_DIR` if you wish to use a different location. See the
[Yocto Project Reference Manual: Variables Glossary](https://docs.yoctoproject.org/ref-manual/variables.html)
for a complete overview of variable definitions.

## Build image

Chose one of the available image types to build

* `minimal`: bare minimum of packages for booting the system. Does not include any
  closed source packages outside of required firmware files.

* `full`: include the full BISDN Linux system, including baseboxd and OF-DPA.

```bash
# build the yocto artifacts
bitbake <minimal|full>
```

The finished image can be found at
`${TMPDIR}/deploy/images/${MACHINE}/onie-bisdn-full-${MACHINE}.bin`.

## Install image

Please refer to our [BISDN Linux docs](https://docs.bisdn.de/getting_started/install_bisdn_linux.html) on how to install the resulting image.
