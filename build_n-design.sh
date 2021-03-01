#!/bin/bash

applypatch() {
        cd "$JDK_DIR/$1"
        echo "applying $1 $2"
        patch -p1 <$2
}

patch_macos_jdkbuild() {
        # JDK-8019470: Changes needed to compile JDK 8 on MacOS with clang compiler
        applypatch . "$PATCH_DIR/jdk8u-8019470.patch"

        # JDK-8152545: Use preprocessor instead of compiling a program to generate native nio constants
        # (fixes genSocketOptionRegistry build error on 10.8)
#       applypatch jdk "$PATCH_DIR/jdk8u-jdk-8152545.patch"

        # fix WARNINGS_ARE_ERRORS handling
        applypatch hotspot "$PATCH_DIR/jdk8u-hotspot-8241285.patch"

        # fix some help messages and Xcode version checks
        applypatch . "$PATCH_DIR/jdk8u-buildfix1.patch"
        # use correct C++ standard library
        #applypatch . "$PATCH_DIR/jdk8u-libcxxfix.patch"
        # misc clang-specific cleanup
        applypatch . "$PATCH_DIR/jdk8u-buildfix2.patch"

        # misc clang-specific cleanup; doesn't apply cleanly on top of 8019470 
        # (use -g1 for fastdebug builds)
        #applypatch . "$PATCH_DIR/jdk8u-buildfix2a.patch"

        # fix for clang crash if base has non-virtual destructor
        applypatch hotspot "$PATCH_DIR/jdk8u-hotspot-8244878.patch"
        
        applypatch hotspot "$PATCH_DIR/jdk8u-hotspot-mac.patch"

        # libosxapp.dylib fails to build on Mac OS 10.9 with clang
        applypatch jdk     "$PATCH_DIR/jdk8u-jdk-8043646.patch"

        applypatch jdk     "$PATCH_DIR/jdk8u-jdk-minversion.patch"
}

patch_macos_jdkquality() {
        # fix concurrency crash; this patch is now in the JDK
        #  applypatch hotspot "$PATCH_DIR/jdk8u-hotspot-8181872.patch"
        # these patches mitigate a clang issue by avoding intrinsic strncat()
        ###### applypatch hotspot "$PATCH_DIR/jdk8u-hotspot-01-8062370.patch"
        ###### applypatch hotspot "$PATCH_DIR/jdk8u-hotspot-02-8060721.patch"
        # disable optimization on some files when using clang 
        # (should check if this is still tha case on newer clang)
        applypatch hotspot "$PATCH_DIR/jdk8u-hotspot-8138820.patch"

        # this is 8062370 and 8060721 together, so it won't apply if those have been applied
        #   applypatch hotspot "$PATCH_DIR/jdk8u-hotspot-metaspace.patch"

        # this patch is incomplete in 8u; it doesn't properly access some test support classes:
        #   applypatch jdk "$PATCH_DIR/jdk8u-jdk-8210403.patch"

        # 8144125: [macOS] java/awt/event/ComponentEvent/MovedResizedTwiceTest/MovedResizedTwiceTest.java failed automatically
        # (rejected as it doen't seem to apply to 8u without lots more work; the test fails either way)
        #   applypatch jdk "$PATCH_DIR/jdk8u-jdk-8144125.patch"
}

JDK_BASE=jdk8u_265

pushd `dirname $0`
SCRIPT_DIR=`pwd`
BUILD_DIR=`pwd`
JDK_DIR="$BUILD_DIR/$JDK_BASE"
PATCH_DIR="$SCRIPT_DIR/jdk8u-patch"
TOOL_DIR="$BUILD_DIR/tools"
TMP_DIR="$TOOL_DIR/tmp"
BOOT_JDK="$TOOL_DIR/jdk8u/Contents/Home"

BUILD_LOG="LOG=debug"
BUILD_MODE=normal
TEST_JDK=false
DEBUG_LEVEL=fastdebug
JDK_CONF=macosx-x86_64-normal-server-$DEBUG_LEVEL
SUBREPOS="corba hotspot jaxp jaxws jdk langtools nashorn"

IS_DARWIN=true
DARWIN_CONFIG="--with-toolchain-type=clang \
    --with-xcode-path="$XCODE_APP" \
    --includedir="$XCODE_DEVELOPER_PREFIX/Toolchains/XcodeDefault.xctoolchain/usr/include" \
    --with-boot-jdk="$BOOT_JDK" --with-native-debug-symbols="none""

#patch_macos_jdkbuild
#patch_macos_jdkquality

popd

#exit 0


pushd "$JDK_DIR"
chmod 755 ./configure

./configure $DARWIN_CONFIG $BUILD_VERSION_CONFIG \
    --with-debug-level=$DEBUG_LEVEL \
    --with-conf-name=$JDK_CONF \
    --with-freetype-include="$TOOL_DIR/freetype/include" \
    --with-freetype-lib="$TOOL_DIR/freetype/objs/.libs"

make images $BUILD_LOG COMPILER_WARNINGS_FATAL=false CONF=$JDK_CONF
find  "$JDK_DIR/build/$JDK_CONF/images" -type f -name libfontmanager.dylib -exec install_name_tool -change /usr/local/lib/libfreetype.6.dylib @rpath/libfreetype.dylib.6 {} \; -print

popd

