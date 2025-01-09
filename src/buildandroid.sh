#!/bin/bash
# COPYRIGHT SOURCE4DROID, ALL RIGHTS RESERVED
# IF YOU PLAN ON USING SOURCE4DROID ON YOUR PROJECTS THEN 
# YOU MUST COMPLY WITH THE MiT License AND CREDIT GUESTSNEEZEOSDEV!!!
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
else
    echo "OS is unsupported."
    exit 1