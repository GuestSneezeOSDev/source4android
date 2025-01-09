#!/bin/bash
# COPYRIGHT SOURCE4DROID, ALL RIGHTS RESERVED
if uname == Linux && if uname == Termux; then
    cp -r ~/.bashrc ~/.bashrc-replace
    echo "uname()
{
    Android
}" >> ~/.bashrc

    pushd `dirname $0`
    . ./thirdparty/src4droid/src4droid.sh
    devtools/bin/vpc /hl2 +everything /mksln everything
    popd
mv ~/.bashrc-replace ~/.bashrc
elif uname == MINGW64_NT; then
    echo "Windows is unsupported!!!"
    exit 1
elif uname == Darwin; then
    echo "MacOS unsupported!!!"
    exit 1
elif uname == BSD; then
    echo "BSD is unsupported!!!"