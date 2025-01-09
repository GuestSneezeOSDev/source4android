#!/bin/bash
# COPYRIGHT SOURCE4DROID, ALL RIGHTS RESERVED
# IF YOU PLAN ON USING THE SOURCE4ANDROID PROJECT THEN YOU MUST ACCEPT THE MiT License aka Credit GuestSneezeOSDev if you plan on using it.
#
# ==== LICENSE ====
#
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

if uname == Linux; then
    SRCDIR=../
    INSTALLDIR=${SRCDIR}/lib/public/android
    mkdir -p ${INSTALLDIR}
    SRC4DROID_HOST=arm-linux-androideabi
    BUILD=linux-x86_64
    NDK_DIR=/mnt/f/soft/android-ndk-r10e
    TOOLCHAIN_VERSION=4.9
    DRIOD_SYSROOT=${NDK_DIR}/platforms/android-21/arch-arm
    CFLAGS=--sysroot=${DRIOD_SYSROOT}
    CPPFLAGS=--sysroot=${DRIOD_SYSROOT}
    AR=${SRC4DROID_HOST}-ar
    RANLIB=${SRC4DROID_HOST}-ranlib
    PATH=${NDK_DIR}/toolchains/${SRC4DROID_HOST}-${TOOLCHAIN_VERSION}/prebuilt/${BUILD}/bin:$PATH

    android_chrooted_install() {
      cp $1 ${SRCDIR}/lib/public/android
    }

    android_chrooted_make() {
      make "$@" -j$(nproc --all) NDK=1 NDK_ABI=armeabi-v7a NDK_PATH=${NDK_DIR}
    }

    cd ${SRCDIR}/thirdparty/

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

    cd ${SRCDIR}/
    cp -r ~/.bashrc ~/.bashrc-replace
    echo "uname()
{
    Android
}" >> ~/.bashrc

    pushd `dirname $0`
    devtools/bin/vpc /hl2 +everything /mksln everything
    popd
    mv ~/.bashrc-replace ~/.bashrc
else
    echo "OS is unsupported."
    exit 1