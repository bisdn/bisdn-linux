# sources directory

The sources directory is initially empty (except for this README file). It
gets populated with configuration files by `kas-container checkout`
after which it looks something like this:

```
sources
├── bitbake
├── meta-bisdn-linux
├── meta-cloud-services
├── meta-erlang
├── meta-ofdpa
├── meta-openembedded
├── meta-open-network-linux
├── meta-poky
├── meta-virtualization
├── openembedded-core
└── README.md
```

Each of the directories in the sources directory is a git repository
containing the source code for a yocto layer from which build recipes
and related files are pulled.
