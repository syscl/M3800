#!/bin/sh

#  cleanUp.sh
#  
#
#  Created by lighting on 16/2/10.
#
export LC_NUMERIC="en_US.UTF-8"
#
# Display style setting.
#
BOLD="\033[1m"
RED="\033[1;31m"
GREEN="\033[1;32m"
BLUE="\033[1;34m"
OFF="\033[m"

#
# Repository location
#
REPO=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ..
#
# Define place
#
decompile="./DSDT/raw/"
precompile="./DSDT/precompile/"
compile="./DSDT/compile/"
tools="./tools/"
raw="./DSDT/raw"
prepare="./DSDT/prepare"
plist="./Kexts/audio/AppleHDA_ALC668.kext/Contents/Info.plist"
config_plist="/Volumes/EFI/EFI/CLOVER/config.plist"
EFI_INFO="./DSDT/EFIINFO"

rm -rf ${precompile} ${compile} ${precompile}
rm -rf ./Kexts/audio/AppleHDA_ALC668.kext
rm ${raw}/*.dsl
rm ${raw}/*.aml

exit 0