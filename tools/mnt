#!/bin/sh

#  mount.sh
#  
#
#  Created by lighting on 16/2/5.
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
EFI_INFO="./DSDT/EFIINFO"


diskutil list
read -p "Enter EFI's IDENTIFIER, e.g. disk0s1: " targetEFI
diskutil mount ${targetEFI}

exit 0