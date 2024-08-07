# build directory

The build directory is initially empty (except for this README file). It
gets populated with configuration files by `kas-container checkout`
after which it looks like this:

```
build
├── conf
│   ├── bblayers.conf
│   ├── local.conf
│   └── templateconf.cfg
└── README.md
```

The build process (i.e., running bitbake) adds additional files and
directories. Here is a directory tree (some file omitted for brevity;
you may not have all these files, depending on your configuration).

```
build
├── cache
├── conf
│   ├── bblayers.conf
│   ├── local.conf
│   └── templateconf.cfg
├── downloads
├── README.md
├── sstate-cache
└── tmp
```

For more information, see the Yocto Project's documentation of
[the build directory](https://docs.yoctoproject.org/ref-manual/structure.html#the-build-directory-build).
