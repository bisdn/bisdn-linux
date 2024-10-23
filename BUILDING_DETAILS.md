# Building details

This document covers details that may be useful to some users.

## Building without containers

We recommend building with containers to ensure a reproducible
build. Building without containers has been known to fail on recent
Linux distributions due to incompatible versions of build tools.

If you want to build without using containers, you can replace the
`kas-container` command with `kas` in a suitable build environment.

On Ubuntu 22.04 LTS (jammy), you would install the required packages
and then run kas:

```shell
sudo apt-get install --no-install-recommends \
  build-essential chrpath diffstat lz4
kas build bisdn-linux.yaml
```

## Building under disk space constraints

If your build runs out of disk space, you will see an error like this:

```
ERROR: No new tasks can be executed since the disk space monitor action is "STOPTASKS"!
ERROR: Immediately halt since the disk space monitor action is "HALT"!
```

To work around this, you can include the [`rm-work.yaml`](rm-work.yaml)
file in your kas configuration. This will remove intermediate files
after a package has been successfully built which reduces the amount
of disk space required substantially:

```shell
kas-container build bisdn-linux.yaml:rm-work.yaml
```

## Troubleshooting

If your build fails, it may be because your [`build`](build) directory
is in an inconsistent state (this can happen, for instance, if the build
process is killed). The `build` directory is rebuilt if you remove it
(or parts of it). Rebuilding `build/downloads` and `build/sstate-cache`
can take a long time, so you may want to remove just `build/tmp` and
restart the build. If that works, there is no need to remove all of
`build`.
