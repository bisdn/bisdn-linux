# BISDN Linux build system

This repository holds the main repo manifest for setting up the build system
for BISDN Linux, based on Yocto.

The build process takes around 3-4 hours with 8 CPU cores and 8 GiB RAM. A single
build requires ~70 GiB of disk space. Adding additional CPU cores speeds up the
build time significantly.

## Prerequisites

* Disk space and RAM

We recommend a minimum of 8 GiB RAM and 150 GiB free disk space for building a single full
image.

* repo tool

Some distros include [repo](https://android.googlesource.com/tools/repo), so
you might be able to install from there (Ubuntu 20.04 however does not provide
those packages).

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

The repo tool requires an executable named `python` in your path and building
open network linux is currently still depending on python2. To suffice this
dependency, we recommend installing python2 with any of the default methods
fitting for your environment. On Ubuntu 20.04 you can install python2 directly
via apt.

```bash
sudo apt-get install python
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
repo init -b BRANCHNAME -u https://github.com/bisdn/bisdn-linux.git

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

> **_NOTE:_** When trying to build a release prior to 4.6.1, please read the
> [Known issues when building older versions](#known-issues-when-building-older-versions) section before starting.

```bash
# build the yocto artifacts
bitbake <minimal|full>
```

The finished image can be found at
`${TMPDIR}/deploy/images/${MACHINE}/onie-bisdn-full-${MACHINE}.bin`.

## Install image

Please refer to our [BISDN Linux docs](https://docs.bisdn.de/getting_started/install_bisdn_linux.html) on how to install the resulting image.

## Known issues when building older versions

* The fix for git **[CVE-2022-24765](https://github.blog/2022-04-12-git-security-vulnerability-announced/)** directly affects the build of BISDN Linux prior to
  version 4.6.1, and will cause it to fail with an error message like:

  ```
  ERROR: python3-oslo.i18n-3.17.0+gitAUTOINC+f2729cd36f-r0 do_install: 'python3 setup.py install --root=/tmp/accton-as4610/work/cortexa9-vfp-poky-linux-gnueabi/python3-oslo.i18n/3.17.0+gitAUTOINC+f2729cd36f-r0/image     --prefix=/usr     --install-lib=/usr/lib/python3.8/site-packages     --install-data=/usr/share' execution failed.
  ERROR: python3-oslo.i18n-3.17.0+gitAUTOINC+f2729cd36f-r0 do_install: Execution of '/tmp/accton-as4610/work/cortexa9-vfp-poky-linux-gnueabi/python3-oslo.i18n/3.17.0+gitAUTOINC+f2729cd36f-r0/temp/run.do_install.2518342' failed with exit code 1
  ERROR: Logfile of failure stored in: /tmp/accton-as4610/work/cortexa9-vfp-poky-linux-gnueabi/python3-oslo.i18n/3.17.0+gitAUTOINC+f2729cd36f-r0/temp/log.do_install.2518342
  Log data follows:
  | DEBUG: Executing python function extend_recipe_sysroot
  | NOTE: Direct dependencies are ['virtual:native:/home/ubuntu/workspace/poky-bisdn-linux/poky/meta/recipes-devtools/python/python3-pbr_5.4.4.bb:do_populate_sysroot', '/home/ubuntu/workspace/poky-bisdn-linux/poky/meta/recipes-core/glibc/glibc_2.31.bb:do_populate_sysroot', '/home/ubuntu/workspace/poky-bisdn-linux/poky/meta/recipes-devtools/python/python3_3.8.13.bb:do_populate_sysroot', '/home/ubuntu/workspace/poky-bisdn-linux/poky/meta/recipes-devtools/quilt/quilt-native_0.66.bb:do_populate_sysroot', '/home/ubuntu/workspace/poky-bisdn-linux/poky/meta/recipes-devtools/python/python3-pbr_5.4.4.bb:do_populate_sysroot', '/home/ubuntu/workspace/poky-bisdn-linux/poky/meta/recipes-devtools/python/python3-pip_20.0.2.bb:do_populate_sysroot', 'virtual:native:/home/ubuntu/workspace/poky-bisdn-linux/poky/meta/recipes-devtools/pseudo/pseudo_git.bb:do_populate_sysroot', '/home/ubuntu/workspace/poky-bisdn-linux/poky/meta/recipes-devtools/gcc/gcc-cross_9.3.bb:do_populate_sysroot', 'virtual:native:/home/ubuntu/workspace/poky-bisdn-linux/poky/meta/recipes-devtools/python/python3_3.8.13.bb:do_populate_sysroot', '/home/ubuntu/workspace/poky-bisdn-linux/poky/meta/recipes-devtools/gcc/gcc-runtime_9.3.bb:do_populate_sysroot', 'virtual:native:/home/ubuntu/workspace/poky-bisdn-linux/poky/meta/recipes-devtools/patch/patch_2.7.6.bb:do_populate_sysroot', 'virtual:native:/home/ubuntu/workspace/poky-bisdn-linux/poky/meta/recipes-devtools/python/python3-setuptools_45.2.0.bb:do_populate_sysroot']
  | NOTE: Installed into sysroot: []
  | NOTE: Skipping as already exists in sysroot: ['python3-pbr-native', 'glibc', 'python3', 'quilt-native', 'python3-pbr', 'python3-pip', 'pseudo-native', 'gcc-cross-arm', 'python3-native', 'gcc-runtime', 'patch-native', 'python3-setuptools-native', 'python3-pip-native', 'linux-libc-headers', 'xz', 'libtirpc', 'libxcrypt', 'autoconf-archive', 'gdbm', 'openssl', 'libnsl2', 'readline', 'bzip2', 'opkg-utils', 'sqlite3', 'zlib', 'libffi', 'util-linux', 'libmpc-native', 'binutils-cross-arm', 'autoconf-native', 'zlib-native', 'flex-native', 'automake-native', 'libtool-native', 'gnu-config-native', 'gmp-native', 'texinfo-dummy-native', 'xz-native', 'mpfr-native', 'openssl-native', 'bzip2-native', 'sqlite3-native', 'libffi-native', 'pkgconfig-native', 'util-linux-native', 'libnsl2-native', 'libtirpc-native', 'gdbm-native', 'readline-native', 'libgcc', 'attr-native', 'unzip-native', 'ncurses', 'libcap-ng', 'bash-completion', 'm4-native', 'gettext-minimal-native', 'libpcre2-native', 'ncurses-native', 'libcap-ng-native']
  | DEBUG: Python function extend_recipe_sysroot finished
  | DEBUG: Executing shell function do_install
  | ERROR:root:Error parsing
  | Traceback (most recent call last):
  |   File "/tmp/accton-as4610/work/cortexa9-vfp-poky-linux-gnueabi/python3-oslo.i18n/3.17.0+gitAUTOINC+f2729cd36f-r0/recipe-sysroot-native/usr/lib/python3.8/site-packages/pbr/core.py", line 96, in pbr
  |     attrs = util.cfg_to_args(path, dist.script_args)
  |   File "/tmp/accton-as4610/work/cortexa9-vfp-poky-linux-gnueabi/python3-oslo.i18n/3.17.0+gitAUTOINC+f2729cd36f-r0/recipe-sysroot-native/usr/lib/python3.8/site-packages/pbr/util.py", line 271, in cfg_to_args
  |     pbr.hooks.setup_hook(config)
  |   File "/tmp/accton-as4610/work/cortexa9-vfp-poky-linux-gnueabi/python3-oslo.i18n/3.17.0+gitAUTOINC+f2729cd36f-r0/recipe-sysroot-native/usr/lib/python3.8/site-packages/pbr/hooks/__init__.py", line 25, in setup_hook
  |     metadata_config.run()
  |   File "/tmp/accton-as4610/work/cortexa9-vfp-poky-linux-gnueabi/python3-oslo.i18n/3.17.0+gitAUTOINC+f2729cd36f-r0/recipe-sysroot-native/usr/lib/python3.8/site-packages/pbr/hooks/base.py", line 27, in run
  |     self.hook()
  |   File "/tmp/accton-as4610/work/cortexa9-vfp-poky-linux-gnueabi/python3-oslo.i18n/3.17.0+gitAUTOINC+f2729cd36f-r0/recipe-sysroot-native/usr/lib/python3.8/site-packages/pbr/hooks/metadata.py", line 25, in hook
  |     self.config['version'] = packaging.get_version(
  |   File "/tmp/accton-as4610/work/cortexa9-vfp-poky-linux-gnueabi/python3-oslo.i18n/3.17.0+gitAUTOINC+f2729cd36f-r0/recipe-sysroot-native/usr/lib/python3.8/site-packages/pbr/packaging.py", line 870, in get_version
  |     raise Exception("Versioning for this project requires either an sdist"
  | Exception: Versioning for this project requires either an sdist tarball, or access to an upstream git repository. It's also possible that there is a mismatch between the package name in setup.cfg and the argument given to pbr.version.VersionInfo. Project name oslo.i18n was given, but was not able to be found.
  | error in setup command: Error parsing /tmp/accton-as4610/work/cortexa9-vfp-poky-linux-gnueabi/python3-oslo.i18n/3.17.0+gitAUTOINC+f2729cd36f-r0/git/setup.cfg: Exception: Versioning for this project requires either an sdist tarball, or access to an upstream git repository. It's also possible that there is a mismatch between the package name in setup.cfg and the argument given to pbr.version.VersionInfo. Project name oslo.i18n was given, but was not able to be found.
  | ERROR: 'python3 setup.py install --root=/tmp/accton-as4610/work/cortexa9-vfp-poky-linux-gnueabi/python3-oslo.i18n/3.17.0+gitAUTOINC+f2729cd36f-r0/image     --prefix=/usr     --install-lib=/usr/lib/python3.8/site-packages     --install-data=/usr/share' execution failed.
  | WARNING: exit code 1 from a shell command.
  | ERROR: Execution of '/tmp/accton-as4610/work/cortexa9-vfp-poky-linux-gnueabi/python3-oslo.i18n/3.17.0+gitAUTOINC+f2729cd36f-r0/temp/run.do_install.2518342' failed with exit code 1
  ERROR: Task (/home/ubuntu/workspace/poky-bisdn-linux/poky/meta-cloud-services/meta-openstack/recipes-devtools/python/python3-oslo.i18n_git.bb:do_install) failed with exit code '1'
  NOTE: Tasks Summary: Attempted 4488 tasks of which 8 didn't need to be rerun and 1 failed.
  
  Summary: 1 task failed:
    /home/ubuntu/workspace/poky-bisdn-linux/poky/meta-cloud-services/meta-openstack/recipes-devtools/python/python3-oslo.i18n_git.bb:do_install
  Summary: There were 25 WARNING messages shown.
  Summary: There were 2 ERROR messages shown, returning a non-zero exit code.
  ```

  To avoid this you can either try building from version 4.6.1 (or newer), or
  disable the git safeguard and manually mark all directories as safe to
  use from by running:

  ```
  git config --global safe.directory '*'
  ```

  > **_WARNING_** This will effectively reintroduce the vulnerability of **CVE-2022-24765**, please
  > read the advisory carefully to make sure you understand the risk.
