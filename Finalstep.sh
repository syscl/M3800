#!/bin/sh

#  Finalstep.sh
#  
#
#  Created by lighting/syscl(PCBeta) on 15/8/25.
#

#
# Lead to lid wake
#

export LC_NUMERIC="en_US.UTF-8"

# Repository location
REPO=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Define place
decompile=${REPO}/DSDT/raw/
precompile=${REPO}/DSDT/precompile/
compile=${REPO}/DSDT/compile/
tools=${REPO}/tools/
raw=${REPO}/DSDT/raw
prepare=${REPO}/DSDT/prepare

kextstat |grep -y Azul &> /dev/null && result=0 || result=1
kextstat |grep -y HD5000 &> /dev/null && HD=0 || HD=1

if [[ $result -eq 0 && $HD -eq 0 ]];
    then
        echo "After scrpit finish, reboot system and enjoy your OS X! --syscl PCBeta"
        esp=$(grep "dev" "${REPO}"/efi)
        diskutil mount ${esp}
        plist=/Volumes/EFI/EFI/CLOVER/config.plist
        /usr/libexec/plistbuddy -c "Set ':Graphics:ig-platform-id' 0x0a260006" "${plist}" &> /dev/null
        /usr/libexec/plistbuddy -c "Print"  "${plist}" | grep "ig-platform-id = 0x0a260006" &> /dev/null && changestat=0 || changestat=1
        if [ $changestat == 0 ];then
            sudo touch /System/Library/Extensions && sudo kextcache -u /
            echo "FINISH! REBOOT!"
        else
            echo "Failed, ensure ${esp}/EFI/CLOVER/config.plist has right config"
            echo "start first script again"
        fi
    else
        exit 0
fi

exit 0

