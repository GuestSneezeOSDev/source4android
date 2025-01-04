#!/bin/bash
# ===============SOURCE4ANDROID===============
# Source4Android is licensed under MIT License,
# so if you do plan on using it you must credit GuestSneezePlayZ in your HL2 Mod or Source Engine-based game.
# ===============LICENSE======================
# MIT License
#
#Copyright (c) 2025 Mohamed
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.

SRCDIR=../..
INSTALLDIR=../../lib/public/android
echo "Editing client to support Android."
${SRCDIR}/game/client/client.vcxproj << EOF
<PropertyGroup Condition="'$(Configuration)|$(Platform)'=='Release|Android'">
  <OutputPath>$(SolutionDir)bin\$(Configuration)\android\</OutputPath>
</PropertyGroup>
<HasSharedItems>true</HasSharedItems>
EOF
echo "Editing client to support Android. Complete"
echo "Editing server to support Android."
${SRCDIR}/game/server/server.vcxproj << EOF
<PropertyGroup Condition="'$(Configuration)|$(Platform)'=='Release|Android'">
  <OutputPath>$(SolutionDir)bin\$(Configuration)\android\</OutputPath>
</PropertyGroup>
<HasSharedItems>true</HasSharedItems>
EOF
echo "Editing server to support Android. Complete"
echo "Creating Libs..."
mkdir -p ../lib/public/android

export SRC4DROID_HOST=arm-linux-androideabi \
BUILD=linux-x86_64 \
NDK_DIR=/mnt/f/soft/android-ndk-r10e \
TOOLCHAIN_VERSION=4.9 \
DRIOD_SYSROOT=${NDK_DIR}/platforms/android-21/arch-arm \
CFLAGS=--sysroot=${DRIOD_SYSROOT} \
CPPFLAGS=--sysroot=${DRIOD_SYSROOT} \
AR=${SRC4DROID_HOST}-ar \
RANLIB=${SRC4DROID_HOST}-ranlib \
PATH=${NDK_DIR}/toolchains/${SRC4DROID_HOST}-${TOOLCHAIN_VERSION}/prebuilt/${BUILD}/bin:$PATH

android_chrooted_install() {
  cp $1 ../../lib/public/android
}

android_chrooted_make() {
  make "$@" -j$(nproc --all) NDK=1 NDK_ABI=armeabi-v7a NDK_PATH=${NDK_DIR}
}

cd ../ # Move to the thirdparty directories

cd StubSteamAPI/
android_chrooted_make
android_chrooted_install libsteam_api.so 
cd ../

cd libiconv-1.15/
./configure --host=$SRC4DROID_HOST --with-sysroot=$SYSROOT --enable-static
android_chrooted_make
android_chrooted_install lib/.libs/libiconv.a
cd ../

cd libjpeg/
conf ./configure --host=$SRC4DROID_HOST --with-sysroot=$SYSROOT
android_chrooted_make
cp .libs/libjpeg.a ../../lib/common/androidarm32
android_chrooted_install .libs/libjpeg.a
cd ../

cd src4droid/
sleep 10