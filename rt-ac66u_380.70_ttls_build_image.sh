#!/bin/sh

DIR_BUILD=$HOME
if [ abc$1 != 'abc' ]; then
  DIR_BUILD=$1
fi

echo "-------------------- install the required packages"
sudo -S dpkg --add-architecture i386
if [ $? != 0 ]; then
  echo "dpkg --add-architectur is failed. Please run this script again."
  exit 1
fi
sudo -S apt update
if [ $? != 0 ]; then
  echo "apt update is failed. Please run this script again."
  exit 1
fi
sudo -S apt -y upgrade
if [ $? != 0 ]; then
  echo "apt upgrade is failed. Please run this script again."
  exit 1
fi
sudo -S apt -y install libtool-bin cmake libproxy-dev uuid-dev liblzo2-dev autoconf automake bash bison \
     bzip2 diffutils file flex m4 g++ gawk groff-base libncurses-dev libtool libslang2 make patch perl pkg-config shtool \
     subversion tar texinfo zlib1g zlib1g-dev git-core gettext libexpat1-dev libssl-dev cvs gperf unzip \
     python libxml-parser-perl gcc-multilib gconf-editor libxml2-dev g++-multilib gitk libncurses5 mtd-utils \
     libncurses5-dev libvorbis-dev git autopoint autogen sed build-essential intltool libelf1:i386 libglib2.0-dev \
     xutils-dev lib32z1-dev lib32stdc++6 xsltproc gtk-doc-tools
if [ $? != 0 ]; then
  echo "apt install is failed. Please run this script again."
  exit 1
fi
sudo -S apt -y install lib32z1-dev lib32stdc++6
if [ $? != 0 ]; then
  echo "apt install is failed. Please run this script again."
  exit 1
fi


echo "-------------------- git clone the legacy asuswrt-merlin repository"
rm -rf $DIR_BUILD/asuswrt-merlin
cd $DIR_BUILD
git clone -c advice.detachedHead=false --branch 380.70 --depth=1 --single-branch https://github.com/RMerl/asuswrt-merlin $2
if [ $? != 0 ]; then
  echo "git clone is failed. Please run this script again."
  exit 2
fi

echo "-------------------- create some symlinks and adjust the PATH environment variable"
sudo -S ln -s -f $DIR_BUILD/asuswrt-merlin/tools/brcm /opt/brcm
sudo -S ln -s -f $DIR_BUILD/asuswrt-merlin/release/src-rt-6.x.4708/toolchains/hndtools-arm-linux-2.6.36-uclibc-4.5.3 /opt/brcm-arm

export PATH=$PATH:/opt/brcm/hndtools-mipsel-linux/bin:/opt/brcm/hndtools-mipsel-uclibc/bin:/opt/brcm-arm/bin

sudo -S mkdir -p /media/ASUSWRT/
sudo -S ln -s -f $DIR_BUILD/asuswrt-merlin /media/ASUSWRT/asuswrt-merlin

echo "-------------------- fix neon missing proxy.h"
cp /usr/include/proxy.h $DIR_BUILD/asuswrt-merlin/release/src/router/neon/

echo "-------------------- fix broken configure script for libdaemon"
cd $DIR_BUILD/asuswrt-merlin/release/src/router/libdaemon
aclocal

echo "-------------------- fix broken configure script for libxml2"
cd $DIR_BUILD/asuswrt-merlin/release/src/router/libxml2
sed -i s/AM_C_PROTOTYPES/#AM_C_PROTOTYPES/g $DIR_BUILD/asuswrt-merlin/release/src/router/libxml2/configure.in
aclocal

echo "-------------------- fix broken configure script for libvorbis"
cd $DIR_BUILD/asuswrt-merlin/release/src/router/libvorbis
aclocal

echo "-------------------- fix broken configure script for libogg"
cd $DIR_BUILD/asuswrt-merlin/release/src/router/libogg
aclocal
automake

echo "-------------------- fix broken configure script for wget"
cd $DIR_BUILD/asuswrt-merlin/release/src/router/wget
aclocal
automake

echo "-------------------- fix broken configure script for tor"
cd $DIR_BUILD/asuswrt-merlin/release/src/router/tor
aclocal
automake

echo "-------------------- fix mksquashfs.c for squashfs"
sed -i '/#include <sys\/stat.h>/a#include <sys\/sysmacros.h>' $DIR_BUILD/asuswrt-merlin/release/src-rt/linux/linux-2.6/scripts/squashfs/mksquashfs.c

echo "-------------------- apply the patch to to support EAP_TTLS/PAP for the legacy asuswrt-merlin"
cd $DIR_BUILD/asuswrt-merlin
curl -sLf https://github.com/ypyd/asuswrt-merlin-ypyd/raw/main/rt-ac66u_380.70_ttls.patch | patch -p0
if [ $? != 0 ]; then
  echo "patch is failed. Please run this script again."
  exit 3
fi

echo "-------------------- build the image"
cd $DIR_BUILD/asuswrt-merlin/release/src-rt-6.x
make clean 
make rt-ac66u
