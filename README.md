boostrap BISDN Linux build system
=========================================

Prerequisites
-------------

* repo tool

  # install
  mkdir ~/bin
  PATH=~/bin:$PATH
  
  curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
  chmod a+x ~/bin/repo

see [1] for further details.

* install your OS specific build essential [2]

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

  # build the yocto artifacts
  bitbake <minimal|full>

  # assemble the final image
  IMAGETYPE="<minimal|full>" ../bisdn-onie-additions/mk_onie2


[1] https://source.android.com/source/using-repo.html
[2] http://www.yoctoproject.org/docs/current/yocto-project-qs/yocto-project-qs.html#packages

