# kas directory

The kas directory contains configuration files for the kas tool to
gather sources and build BISDN Linux images.

The files in this directory can be passed to kas to build images,
while the files in the `include` directory are included to provide
generic defaults or modify an image.

The files in the `lock` directory record the versions of the
layer repositories when specific image versions were built. They
can be used to reproduce the older image versions. See the
`[BUILDING.md](../BUILDING.md)` file for more information.
