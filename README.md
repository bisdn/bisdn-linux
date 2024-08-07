# BISDN Linux build system

This repository holds the files for building the
[BISDN Linux](https://docs.bisdn.de/) network operating system.

Pre-built release images can be downloaded from the
[BISDN Linux images](https://docs.bisdn.de/download_images.html) page.
[Nightly builds](http://repo.bisdn.de/nightly_builds/) are also available.

If you want to build your own BISDN Linux images, you can use the files
in this repo and the kas automation tool.

This document provides a quick guide on how to build a BISDN Linux
image. For more detailed information on building and customizing
BISDN Linux images as well as hints for troubleshooting, please refer to
[BUILDING.md](BUILDING.md).

## Supported switches

A list of supported switches can be found at
[BISDN Linux images]](https://docs.bisdn.de/download_images.html).

## Build requirements

### Disk space and RAM

We recommend a minimum of 8 GiB RAM and 150 GiB free disk space for
building a single full image.

### Software requirements

Our build system uses
[kas](https://kas.readthedocs.io/en/latest/userguide.html) to fetch the
source repositories and to configure the build. While it is possible to
run `kas` directly on your build host, we recommend using `kas-container`
because it provides a reproducible build environment.

Therefore, you should install on your build host:

- kas. Some Linux distributions offer their own kas package, but some are
  too old to work with our kas files. We recommend installing kas as a
  Python package using pip.

- a container management tool. For the rest of this document, we will assume
  you have docker installed, but podman should work as well.

### Time

The build process takes around 3-4 hours with 8 CPU cores and 8
GiB RAM. A single build requires about 70 GiB of disk space. Adding
additional CPU cores speeds up the build time significantly.

Subsequent builds are much faster because sources (kept in the `sources`
directory) are not downloaded again and a number of intermediate build
artifacts are cached in the `build` directory.

## Building a BISDN Linux image

### x86_64 platforms

To build from the the latest sources an image that works on all x86_64
platforms supported by BISDN Linux, run this command in the root of this
repository:

```bash
kas-container build kas/bisdn-linux.yml
```

After the build process finishes, your image will be in
`build/tmp/deploy/images/generic-x86-64/`. A symlink named
`onie-bisdn-full-generic-x86-64.bin` will point to the actual image
file named `onie-bisdn-full-generic-x86-64-<timestamp>.bin`.

### ARM platforms (Edgecore AS4610)

To build an image that works on all ARM platforms supported by BISDN Linux,
run this command in the root of this repository:

```bash
kas-container build kas/bisdn-linux.yml:kas/include/armel-iproc.yml
```

After the build process finishes, your image will be in
`build/tmp/deploy/images/generic-armel-iproc/`. A symlink named
`onie-bisdn-full-generic-armel-iproc.bin` will point to the actual image
file named `onie-bisdn-full-generic-armel-iproc-<timestamp>.bin`.

## Installing a BISDN Linux image

Please refer to our
[BISDN Linux docs](https://docs.bisdn.de/getting_started/install_bisdn_linux.html)
on how to install the resulting image.
