boostrap BISDN Linux build system
=========================================

This repository holds the main repo manifest for setting up the build system
for BISDN Linux, based on Yocto.

Prerequisites
-------------

* repo tool

Many distros include repo, so you might be able to install from there.

  # Debian/Ubuntu.
  sudo apt-get install repo

  # Gentoo.
  sudo emerge dev-vcs/repo

You can install it manually as well as it's a single script.

  # install
  mkdir ~/bin
  PATH=~/bin:$PATH
  
  curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
  chmod a+x ~/bin/repo

see [1] for further details.

* install your OS specific build essentials for Yocto [2]

Some packages may require additional packages to be present on the host.

Bootsrap build system
---------------------

  # init repo
  mkdir -p ~/workspace/poky-bisdn-linux
  cd !$
  repo init -b BRANCHNAME -u git@gitlab.bisdn.de:yocto-projects/bisdn-linux.git

  # sync repos
  repo sync

  # init build system
  . poky/oe-init-build-env poky/build-bisdn-linux/

Configure target machine
------------------------

Edit conf/local.conf and set `MACHINE` to your desired target.

Build image
-----------

Chose one the desired image types to build

* `minimal`: bare minimum of packages for booting the system. Does not include any
  closed source packages outside of required firmware files.

* `full`: include the full BISDN Linux system, including baseboxd and OF-DPA.

  # build the yocto artifacts
  bitbake <minimal|full>

  # assemble the final image
  IMAGETYPE="<minimal|full>" ../bisdn-onie-additions/mk_onie2


[1] https://source.android.com/source/using-repo.html
[2] https://docs.yoctoproject.org/3.1.7/ref-manual/ref-system-requirements.html

