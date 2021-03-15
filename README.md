# Compiling OpenJDK8u on Big Sur using Xcode 12

How to compile JDK 8 with the latest Xcode on the latest macOS.

Currently (September 2019), openjdk jdk8u can only be compiled with XCode 4, which won't run on the latest macOS.
This repo contains patches and information for setting up an environment to compile a JDK using the very latest tools.

By default, build8.sh will build a JDK without Shenandoah GC or JavaFX.  Edit the script to turn on these if you need them, or set environment variables (as seen at the top of the script).

A version of this patch has been submitted to the jdk8u-dev mailing list.

### Quick start:

The easiest way to get a working JDK8u is:

```
  git clone https://github.com/stooke/jdk8u-xcode10.git
  ./jdk8u-xcode10/build8.sh
```

### Caveats:
- This patch only works with XCode 9, 10, 11 or 12. (Actually 9-11 have not been tested recently)
- Some of the patches included apply with offsets, etc.
- This patch will produce a JDK that runs on macOS 10.9 and above; the original code runs on macOS 10.7 and above.
- The resultant JDK has not been run through TCK, but can be used to build Graal.

- If you see a crash in a destructor, and the destructor is not virtual, try making the destructor virtual and see if it still crashes.  If the issue is fixed, please email me.

## The quick way

Clone this repo and run _build8_.  You may edit this script to build jdk8u-dev with Shenandoah GC and/or JavaFX.

## Install Prerequisites

Some of these are also required for building JDK 11, so your efforts won't be wasted here.  The build script will download and install these (except for Xcode; that one's on you) in a local location, so no action is required if you use these scripts

Install XCode 9, 10, 11, 12 autoconf, freetype and mercurial.
Install a bootstrap JDK; either JDK 7 or JDK 8.  
If you have a system JDK 8 installed, the build should find it, but it should be ignored if you use build8.sh.

```
curl -O -L http://ftpmirror.gnu.org/autoconf/autoconf-2.69.tar.gz
tar -xzf autoconf-2.69.tar.gz
cd autoconf-2.69
./configure --prefix=`pwd`
make install

curl -O https://nongnu.freemirror.org/nongnu/freetype/freetype-2.9.tar.gz
tar -xvf freetype-2.9.tar.gz
cd freetype-2.9
./configure
make

curl -O https://www.mercurial-scm.org/release/mercurial-4.9.tar.gz
tar -xvf mercurial-4.9.tar.gz
cd mercurial-4.9
make local

curl -O -L https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u202-b08/OpenJDK8U-jdk_x64_mac_hotspot_8u202b08.tar.gz
tar -xvf OpenJDK8U-jdk_x64_mac_hotspot_8u202b08.tar.gz
```

## download the JDK and all subrepos

```
hg clone http://hg.openjdk.java.net/jdk8u/jdk8u-dev jdk8u-dev
cd jdk8u-dev
chmod 755 get_source.sh configure
./get_source.sh
```

## install the patches

```
cd jdk8u-dev
hg import --no-commit ../jdk8u-xcode10/jdk8u-patch/mac-jdk8u.patch
cd hotspot
hg import --no-commit ../../jdk8u-xcode10/jdk8u-patch/mac-jdk8u-hotspot.patch
cd ../jdk
hg import --no-commit ../../jdk8u-xcode10/jdk8u-patch/mac-jdk8u-jdk.patch
```

## configure the JDK

```
cd jdk8u-dev
chmod 755 ./configure ./get_source.sh
./configure --with-toolchain-type=clang --with-boot-jdk=`pwd`/../tools/jdk8u202-b08/Contents/Home --with-freetype-include=`pwd`/../tools/freetype-2.9/include --with-freetype-lib=`pwd`/../tools/freetype-2.9/objs/.libs
```
Optionally, add `--with-debug-level=slowdebug` to debug the JDK
If you're using the XCode 11 beta, disable precompiled headers: `--disable-precompiled-headers`.  There seems to be an issue with honouring include file paths.

## build the JDK

```
make images COMPILER_WARNINGS_FATAL=false
```

## run!

```
./build/maxosx-x86_64-normal-server-release/images/j2sdk-image/bin/java
./build/maxosx-x86_64-normal-server-slowdebug/images/j2sdk-image/bin/java
```

