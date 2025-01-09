#!/bin/bash
# COPYRIGHT SOURCE4DROID, ALL RIGHTS RESERVED
if uname == Linux && if uname == Termux; then
    cp -r ~/.bashrc ~/.bashrc-replace
    echo "uname()
{
    Android
}"

    pushd `dirname $0`
    . ./thirdparty/src4droid/src4droid.sh
    devtools/bin/vpc /hl2 +everything /mksln everything
    popd
mv ~/.bashrc-replace ~/.bashrc
else
    echo "MacOS & FreeBSD is unsupported"