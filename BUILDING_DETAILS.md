# Building details

This document covers details that may be useful to some users.

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
