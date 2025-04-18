# BISDN Linux build system

[![BISDN Linux CI status](https://github.com/bisdn/bisdn-linux/actions/workflows/build-bisdn-linux.yml/badge.svg)](https://github.com/bisdn/bisdn-linux/actions/workflows/build-bisdn-linux.yml)

This repository holds files for building the
[BISDN Linux](https://docs.bisdn.de/) network operating system.

Pre-built release images can be downloaded from the
[BISDN Linux images](https://docs.bisdn.de/download_images.html) page.
[Nightly builds](http://repo.bisdn.de/nightly_builds/) are also available.

If you want to build your own BISDN Linux images, you can use the files
in this repo and the [kas](https://github.com/siemens/kas) automation
tool. The only file that you will need is the kas configuration file
[`bisdn-linux.yaml`](bisdn-linux.yaml). All other files in this repo
are documentation or for the benefit of our CI/CD and release management
systems.

The remainder of this document provides a quick guide on how to build
a BISDN Linux image. For further customization, build optimization, and
troubleshooting, please refer to [BUILDING_DETAILS.md](BUILDING_DETAILS.md).

## Supported switches

A list of supported switches can be found at
[BISDN Linux images](https://docs.bisdn.de/download_images.html).

## Build requirements

### Hardware requirements

We recommend a build host with 32 CPU cores, 32 GiB RAM and 150 GiB free
disk space for building a full image. You may get away with less, but
you risk running into out-of-memory errors, a full disk, or a slow build.

### Software requirements

Our build system uses
[kas](https://kas.readthedocs.io/en/latest/userguide.html) to fetch the
source repositories and to configure the build. While it is possible to
run `kas` directly on your build host, we recommend using
[`kas-container`](https://kas.readthedocs.io/en/latest/userguide/kas-container.html)
because it provides a reproducible build environment.

Your build host should be running Linux and have the following software
components installed:

- kas. Some Linux distributions offer their own kas package, but they
  may be too old to work with our kas files. We recommend installing
  kas as a Python package (using pip, pipx, or a similar tool).

- a container management tool. For the rest of this document, we will assume
  you have docker installed, but podman should work as well.

### Time and disk space

Expect the build process to take a bit over an hour with 32 CPU cores
and 32 GiB RAM. Adding additional CPU cores speeds up the build time
significantly.

Subsequent builds are much faster (taking less than 10 minutes with a warm
build cache) because source repos (kept in the `sources` directory) are not
downloaded again and (more importantly) a number of intermediate build
artifacts are cached in the `build` directory.

A single build requires about 100 GiB of disk space. The cache directories in
`build` directory tend to grow slowly when building new versions.

## Building a BISDN Linux image

BISDN Linux supports two different architectures: Broadcom XGS iProc (ARM), and
Intel x86-64.

To select the target machine for BISDN Linux, pass the appropriate name via
the`KAS_MACHINE` environment variable:

* `generic-armel-iproc` for devices based on Broadcom XGS iProc (Accton AS4610 series)
* `generic-x86-64` for devices with an Intel x86 host CPU (all other supported devices)

To build the image from the latest sources, clone this repo and run the
following command in its root directory, e.g.:

```bash
KAS_MACHINE=generic-x86-64 kas-container build bisdn-linux.yaml
```

After the build process has finished, your image will be in
`build/tmp/deploy/images/<KAS_MACHINE>/`. A symlink named
`onie-bisdn-full-<KAS_MACHINE>.bin` will point to the actual image
file named `onie-bisdn-full-<KAS_MACHINE>-<timestamp>.bin`.

## Installing a BISDN Linux image

Please refer to our
[BISDN Linux docs](https://docs.bisdn.de/getting_started/install_bisdn_linux.html)
on how to install the resulting image.
