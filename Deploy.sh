#!/bin/sh

#
# syscl/Yating Zhou/lighting from bbs.PCBeta.com
# Merge for Dell Precision M3800 and XPS15 (9530).
#
export LC_NUMERIC="en_US.UTF-8"
#
# Display style setting.
#
BOLD="\033[1m"
RED="\033[0;31m"
GREEN="\033[0;32m"
BLUE="\033[1;34m"
OFF="\033[m"

#
# Repository location
#
REPO=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

#
# Define place
#
decompile=${REPO}/DSDT/raw/
precompile=${REPO}/DSDT/precompile/
compile=${REPO}/DSDT/compile/
tools=${REPO}/tools/
raw=${REPO}/DSDT/raw
prepare=${REPO}/DSDT/prepare

#
# Sync all files from https://github.com/syscl/M3800
#

#
# Check if github is available
#
timeout=5
#
# Define target website
#
target_website=https://github.com/syscl/M3800

# Detect whether the website is available
echo Please wait ...
echo Updating ...
ret_code=`curl -I -s --connect-timeout $timeout $target_website -w %{http_code} | tail -n1`

if [ "x$ret_code" = "x200" ]; then
cd ${REPO}
git pull
else
echo https://github.com/syscl/M3800 is not available at this time
echo Relink again.
fi
#
# Decide which progress to finish [syscl/Yating]
# Merge two step Initialstep.sh and Finalstep.sh into one.
#
# Note : This "if" is to make two steps clear.
#
if [ ! -f ${REPO}/efi ];then
#
# Generate define directionaries
#
if [ ! -d "${prepare}" ];then
mkdir "${prepare}"
fi

if [ ! -d "${compile}" ];then
mkdir "${compile}"
fi

if [ ! -d "${precompile}" ];then
mkdir "${precompile}"
fi

#
# Define variables
# Gvariables stands for getting datas from OS X
#
gProductVersion=""
#
# Choose ESP by syscl/Yating
#
diskutil list
read -p "Enter EFI's IDENTIFIER, e.g. disk0s1: " targetEFI
echo "${targetEFI}"
esp=$(echo "/${targetEFI}")
echo /dev${esp} >${REPO}/efi
diskutil mount /dev${esp}
#
# Copy origin aml to raw
#
if [ -f /Volumes/EFI/EFI/CLOVER/ACPI/origin/DSDT.aml ];then
cp /Volumes/EFI/EFI/CLOVER/ACPI/origin/DSDT.aml /Volumes/EFI/EFI/CLOVER/ACPI/origin/SSDT-*.aml "${decompile}"
else
echo "Warning!! DSDT and SSDTs doesn't exist! Press Fn+F4 under Clover to dump ACPI tables"
# ERROR.
#
# Note: The exit value can be anything between 0 and 255 and thus -1 is actually 255
#       but we use -1 here to make it clear (obviously) that something went wrong.
#
exit -1
fi
#
# Decompile dsdt
#
cd "${REPO}"

"${REPO}"/tools/iasl -w1 -da -dl "${REPO}"/DSDT/raw/DSDT.aml "${REPO}"/DSDT/raw/SSDT-*.aml

# Search specification tables by syscl/Yating Zhou 

# DptfTa
for num in $(seq 1 20)
do
    grep "DptfTa" "${REPO}"/DSDT/raw/SSDT-${num}.dsl &> /dev/null && result=0 || result=1
    if [ "${result}" == 0 ];then
    DptfTa=SSDT-$num
    fi
done

# SaSSDT
for num in $(seq 1 20)
do
    grep "SaSsdt" "${REPO}"/DSDT/raw/SSDT-${num}.dsl &> /dev/null && result=0 || result=1
    if [ "${result}" == 0 ];then
    SaSsdt=SSDT-$num
    fi
done

# SgRef
for num in $(seq 1 20)
do
    grep "SgRef" "${REPO}"/DSDT/raw/SSDT-${num}.dsl &> /dev/null && result=0 || result=1
    if [ "${result}" == 0 ];then
    SgRef=SSDT-$num
    fi
done

# OptRef
for num in $(seq 1 20)
do
    grep "OptRef" "${REPO}"/DSDT/raw/SSDT-${num}.dsl &> /dev/null && result=0 || result=1
    if [ "${result}" == 0 ];then
    OptRef=SSDT-$num
    fi
done

# DSDT Fix

"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/DSDT.dsl "${REPO}"/DSDT/patches/syntax/fix_PARSEOP_ZERO.txt "${REPO}"/DSDT/raw/DSDT.dsl

echo "${BOLD}[syn] Fix ADBG Error${OFF}"
"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/DSDT.dsl "${REPO}"/DSDT/patches/syntax/fix_ADBG.txt "${REPO}"/DSDT/raw/DSDT.dsl

echo "${BOLD}[gfx] Rename GFX0 to IGPU${OFF}"
"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/DSDT.dsl "${REPO}"/DSDT/patches/graphics/graphics_Rename-GFX0.txt "${REPO}"/DSDT/raw/DSDT.dsl

echo "${BOLD}[usb] 7-series/8-series USB${OFF}"
"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/DSDT.dsl "${REPO}"/DSDT/patches/usb/usb_7-series.txt "${REPO}"/DSDT/raw/DSDT.dsl

echo "${BOLD}[bat] Acer Aspire E1-571${OFF}"
"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/DSDT.dsl "${REPO}"/DSDT/patches/battery/battery_Acer-Aspire-E1-571.txt "${REPO}"/DSDT/raw/DSDT.dsl

echo "${BOLD}[sys] IRQ Fix${OFF}"
"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/DSDT.dsl "${REPO}"/DSDT/patches/system/system_IRQ.txt "${REPO}"/DSDT/raw/DSDT.dsl

echo "${BOLD}[sys] SMBus Fix${OFF}"
"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/DSDT.dsl "${REPO}"/DSDT/patches/system/system_SMBUS.txt "${REPO}"/DSDT/raw/DSDT.dsl

echo "${BOLD}[sys] OS Check Fix${OFF}"
"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/DSDT.dsl "${REPO}"/DSDT/patches/system_OSYS.txt "${REPO}"/DSDT/raw/DSDT.dsl

echo "${BOLD}[sys] AC Adapter Fix${OFF}"
"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/DSDT.dsl "${REPO}"/DSDT/patches/system/system_ADP1.txt "${REPO}"/DSDT/raw/DSDT.dsl

echo "${BOLD}[sys] Add MCHC${OFF}"
"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/DSDT.dsl "${REPO}"/DSDT/patches/system/system_MCHC.txt "${REPO}"/DSDT/raw/DSDT.dsl

echo "${BOLD}[sys] Fix _WAK Arg0 v2${OFF}"
"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/DSDT.dsl "${REPO}"/DSDT/patches/system/system_WAK2.txt "${REPO}"/DSDT/raw/DSDT.dsl

echo "${BOLD}[sys] Add IMEI${OFF}"
"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/DSDT.dsl "${REPO}"/DSDT/patches/system/system_IMEI.txt "${REPO}"/DSDT/raw/DSDT.dsl

echo "${BOLD}[sys] Fix Non-zero Mutex${OFF}"
"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/DSDT.dsl "${REPO}"/DSDT/patches/system/system_Mutex.txt "${REPO}"/DSDT/raw/DSDT.dsl

echo "${BOLD}[sys] Add Haswell LPC${OFF}"
"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/DSDT.dsl "${REPO}"/DSDT/patches/misc/misc_Haswell-LPC.txt "${REPO}"/DSDT/raw/DSDT.dsl

echo "${BOLD}Kexts/audio Layout${OFF}"
"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/DSDT.dsl "${REPO}"/DSDT/patches/Kexts/audio_HDEF-layout1.txt "${REPO}"/DSDT/raw/DSDT.dsl

echo "${BOLD}Rename B0D3 to HDAU${OFF}"
"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/DSDT.dsl "${REPO}"/DSDT/patches/Kexts/audio_B0D3_HDAU.txt "${REPO}"/DSDT/raw/DSDT.dsl

echo "${BOLD}Remove GLAN device${OFF}"
"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/DSDT.dsl "${REPO}"/DSDT/patches/remove_glan.txt "${REPO}"/DSDT/raw/DSDT.dsl

########################
# DptfTa Patches
########################

echo "${BLUE}[${DptfTa}]${OFF}: Patching ${DptfTa}.dsl in "${REPO}"/DSDT/raw"

echo "${BOLD}_BST package size${OFF}"
"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/${DptfTa}.dsl "${REPO}"/DSDT/patches/_BST-package-size.txt "${REPO}"/DSDT/raw/${DptfTa}.dsl

echo "${BOLD}[gfx] Rename GFX0 to IGPU${OFF}"
"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/${DptfTa}.dsl "${REPO}"/DSDT/patches/graphics/graphics_Rename-GFX0.txt "${REPO}"/DSDT/raw/${DptfTa}.dsl

########################
# SaSsdt Patches
########################

echo "${BLUE}[${SaSsdt}]${OFF}: Patching ${SaSsdt}.dsl in "${REPO}"/DSDT/raw"

echo "${BOLD}[gfx] Rename GFX0 to IGPU${OFF}"
"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/${SaSsdt}.dsl "${REPO}"/DSDT/patches/graphics/graphics_Rename-GFX0.txt "${REPO}"/DSDT/raw/${SaSsdt}.dsl


"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/${SaSsdt}.dsl "${REPO}"/DSDT/patches/syscl_Iris_Pro.txt "${REPO}"/DSDT/raw/${SaSsdt}.dsl

echo "${BOLD}[gfx] Brightness fix (Haswell)${OFF}"
"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/${SaSsdt}.dsl "${REPO}"/DSDT/patches/graphics/graphics_PNLF_haswell.txt "${REPO}"/DSDT/raw/${SaSsdt}.dsl

echo "${BOLD}Rename B0D3 to HDAU${OFF}"
"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/${SaSsdt}.dsl "${REPO}"/DSDT/patches/Kexts/audio_B0D3_HDAU.txt "${REPO}"/DSDT/raw/${SaSsdt}.dsl

echo "${BOLD}Insert HDAU device${OFF}"
"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/${SaSsdt}.dsl "${REPO}"/DSDT/patches/Kexts/audio_Intel_HD4600.txt "${REPO}"/DSDT/raw/${SaSsdt}.dsl

########################
# SgRef Patches
########################

echo "${BLUE}[${SgRef}]${OFF}: Patching SSDT-13 in "${REPO}"/DSDT/raw"

echo "${BOLD}[gfx] Rename GFX0 to IGPU${OFF}"
"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/${SgRef}.dsl "${REPO}"/DSDT/patches/graphics/graphics_Rename-GFX0.txt "${REPO}"/DSDT/raw/${SgRef}.dsl

########################
# OptRef Patches
########################

echo "${BLUE}[${OptRef}]${OFF}: Patching SSDT-15 in "${REPO}"/DSDT/raw"

echo "${BOLD}Remove invalid operands${OFF}"
"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/${OptRef}.dsl "${REPO}"/DSDT/patches/WMMX-invalid-operands.txt "${REPO}"/DSDT/raw/${OptRef}.dsl

echo "${BOLD}[gfx] Rename GFX0 to IGPU${OFF}"
"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/${OptRef}.dsl "${REPO}"/DSDT/patches/graphics/graphics_Rename-GFX0.txt "${REPO}"/DSDT/raw/${OptRef}.dsl

echo "${BOLD}Disable Nvidia card (Non-operational in OS X)${OFF}"
"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/${OptRef}.dsl "${REPO}"/DSDT/patches/graphics_Disable_Nvidia.txt "${REPO}"/DSDT/raw/${OptRef}.dsl

# Copy raw tables to compile
cp "${raw}"/SSDT-*.aml "$compile"

# Finish rest progress
cp "${raw}/"*.dsl "${precompile}"

"${REPO}"/tools/iasl -vr -w1 -ve -p "${compile}"DSDT.aml "${precompile}"DSDT.dsl
"${REPO}"/tools/iasl -vr -w1 -ve -p "${compile}"${DptfTa}.aml "${precompile}"${DptfTa}.dsl
"${REPO}"/tools/iasl -vr -w1 -ve -p "${compile}"${SaSsdt}.aml "${precompile}"${SaSsdt}.dsl
"${REPO}"/tools/iasl -vr -w1 -ve -p "${compile}"${SgRef}.aml "${precompile}"${SgRef}.dsl
"${REPO}"/tools/iasl -vr -w1 -ve -p "${compile}"${OptRef}.aml "${precompile}"${OptRef}.dsl

cp "${prepare}"/SSDT-rmne.aml "${compile}"
#
# Detect which SSDT for processor to be installed.
#
if [[ `sysctl machdep.cpu.brand_string` == *"i7-4702HQ"* ]]
then
echo "${BLUE}[PRgen]${OFF}: Intel ${BOLD}i7-4702HQ${OFF} processor found"
cp "${prepare}"/CpuPm-4702HQ.aml "${compile}"/SSDT-pr.aml
fi

if [[ `sysctl machdep.cpu.brand_string` == *"i7-4712HQ"* ]]
then
echo "${BLUE}[PRgen]${OFF}: Intel ${BOLD}i7-4712HQ${OFF} processor found"
cp "${prepare}"/CpuPm-4712HQ.aml "${compile}"/SSDT-pr.aml
fi

rm "${compile}"SSDT-*x.aml

##################################


#
# Check if Clover is in place [syscl/Yating Zhou]
#
if [ ! -d /Volumes/EFI/EFI/CLOVER ];then
#
# Not installed
#
    echo "Clover does not install on EFI, please reinstall Clover to EFI and try again."
# ERROR.
#
# Note: The exit value can be anything between 0 and 255 and thus -1 is actually 255
#       but we use -1 here to make it clear (obviously) that something went wrong.
#
exit -1
fi

if [ ! -d /Volumes/EFI/EFI/CLOVER/ACPI/patched ];then
mkdir /Volumes/EFI/EFI/CLOVER/ACPI/patched
fi

#
# Copy AML to Destination Place
#

cp "${compile}"*.aml /Volumes/EFI/EFI/CLOVER/ACPI/patched

#
# Check OS generation
#
gProductVersion="$(sw_vers -productVersion)"
#
# Gain generation of OS X
#
gOSVersion=$(echo ${gProductVersion:3:2} | tr -d '.')

#
# Copy KEXTs to Destiantion Place
#
echo "\n"
echo "Copying kexts to ${esp}/EFI/CLOVER/kexts/10.${gOSVersion}"
cp -R "${REPO}/Kexts/"*.kext "/Volumes/EFI/EFI/CLOVER/kexts/10.${gOSVersion}"/

#
# Finish operation of configuration on booting progress [syscl/Yating Zhou]
#

#
# Install AppleHDA by darkvoid
#
echo "${GREEN}[HDA]${OFF}: Creating AppleHDA injection kernel extension for ${BOLD}ALC668${OFF}"
cd "${REPO}"

plist=./Kexts/audio/AppleHDA_ALC668.kext/Contents/Info.plist

echo "       --> ${BOLD}Creating AppleHDA_ALC668 file layout${OFF}"
rm -R ./Kexts/audio/AppleHDA_ALC668.kext 2&>/dev/null

cp -R /System/Library/Extensions/AppleHDA.kext ./Kexts/audio/AppleHDA_ALC668.kext
rm -R ./Kexts/audio/AppleHDA_ALC668.kext/Contents/Resources/*
rm -R ./Kexts/audio/AppleHDA_ALC668.kext/Contents/PlugIns
rm -R ./Kexts/audio/AppleHDA_ALC668.kext/Contents/_CodeSignature
rm -R ./Kexts/audio/AppleHDA_ALC668.kext/Contents/MacOS/AppleHDA
rm ./Kexts/audio/AppleHDA_ALC668.kext/Contents/version.plist
ln -s /System/Library/Extensions/AppleHDA.kext/Contents/MacOS/AppleHDA ./Kexts/audio/AppleHDA_ALC668.kext/Contents/MacOS/AppleHDA

echo "       --> ${BOLD}Copying AppleHDA_ALC668 Kexts/audio platform & layouts${OFF}"
cp ./Kexts/audio/*.zlib ./Kexts/audio/AppleHDA_ALC668.kext/Contents/Resources/

echo "       --> ${BOLD}Configuring AppleHDA_ALC668 Info.plist${OFF}"
replace=`/usr/libexec/plistbuddy -c "Print :NSHumanReadableCopyright" $plist | perl -Xpi -e 's/(\d*\.\d*)/9\1/'`
/usr/libexec/plistbuddy -c "Set :NSHumanReadableCopyright '$replace'" $plist
replace=`/usr/libexec/plistbuddy -c "Print :CFBundleGetInfoString" $plist | perl -Xpi -e 's/(\d*\.\d*)/9\1/'`
/usr/libexec/plistbuddy -c "Set :CFBundleGetInfoString '$replace'" $plist
replace=`/usr/libexec/plistbuddy -c "Print :CFBundleVersion" $plist | perl -Xpi -e 's/(\d*\.\d*)/9\1/'`
/usr/libexec/plistbuddy -c "Set :CFBundleVersion '$replace'" $plist
replace=`/usr/libexec/plistbuddy -c "Print :CFBundleShortVersionString" $plist | perl -Xpi -e 's/(\d*\.\d*)/9\1/'`
/usr/libexec/plistbuddy -c "Set :CFBundleShortVersionString '$replace'" $plist
/usr/libexec/plistbuddy -c "Add ':HardwareConfigDriver_Temp' dict" $plist
/usr/libexec/plistbuddy -c "Merge /System/Library/Extensions/AppleHDA.kext/Contents/PlugIns/AppleHDAHardwareConfigDriver.kext/Contents/Info.plist ':HardwareConfigDriver_Temp'" $plist
/usr/libexec/plistbuddy -c "Copy ':HardwareConfigDriver_Temp:IOKitPersonalities:HDA Hardware Config Resource' ':IOKitPersonalities:HDA Hardware Config Resource'" $plist
/usr/libexec/plistbuddy -c "Delete ':HardwareConfigDriver_Temp'" $plist
/usr/libexec/plistbuddy -c "Delete ':IOKitPersonalities:HDA Hardware Config Resource:HDAConfigDefault'" $plist
/usr/libexec/plistbuddy -c "Delete ':IOKitPersonalities:HDA Hardware Config Resource:PostConstructionInitialization'" $plist
/usr/libexec/plistbuddy -c "Add ':IOKitPersonalities:HDA Hardware Config Resource:IOProbeScore' integer" $plist
/usr/libexec/plistbuddy -c "Set ':IOKitPersonalities:HDA Hardware Config Resource:IOProbeScore' 2000" $plist
/usr/libexec/plistbuddy -c "Merge ./Kexts/audio/ahhcd.plist ':IOKitPersonalities:HDA Hardware Config Resource'" $plist

echo "       --> ${BOLD}Created AppleHDA_ALC668.kext${OFF}"
sudo cp -R ./Kexts/audio/AppleHDA_ALC668.kext /Library/Extensions
echo "       --> ${BOLD}Installed AppleHDA_ALC668.kext to /Library/Extensions${OFF}"
sudo cp -R ./Kexts/audio/CodecCommander.kext /Library/Extensions
echo "       --> ${BOLD}Installed CodecCommander.kext to /Library/Extensions${OFF}"
#
# Repair the permission by syscl/Yating Zhou
#
sudo chmod -R 755 /Library/Extensions/AppleHDA_ALC668.kext
sudo chown -R root:wheel /Library/Extensions/AppleHDA_ALC668.kext
sudo chmod -R 755 /Library/Extensions/CodecCommander.kext
sudo chown -R root:wheel /Library/Extensions/CodecCommander.kext

#
# Check if your resolution is 1920*1080 or 3200 x 1800 by syscl/Yating Zhou.
# Note: You need to change System Agent (SA) Configuration—>Graphics Configuration->DVMT Pre-Allocated->『128MB』
#
echo "${BLUE}Note${OFF}: You need to change ${BOLD} System Agent (SA) Configuration—>Graphics Configuration->DVMT Pre-Allocated->${RED} ${BOLD}『128MB』${OFF}"
if [[ `system_profiler SPDisplaysDataType` == *"1920 x 1080"* ]]
then
echo "${BLUE}[Display]${OFF}: Resolution ${BOLD} 1920 x 1080${OFF} found"
cp ./CLOVER/1920x1080_config.plist /Volumes/EFI/EFI/CLOVER/config.plist
else
echo "${BLUE}[Display]${OFF}: Resolution ${BOLD} 3200 x 1800${OFF} found"
#
# Patch IOKit.
#
echo "${GREEN}[IOKit]${OFF}: Patching IOKit for maximum pixel clock"
sudo perl -i.bak -pe 's|\xB8\x01\x00\x00\x00\xF6\xC1\x01\x0F\x85|\x33\xC0\x90\x90\x90\x90\x90\x90\x90\xE9|sg' /System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit
sudo codesign -f -s - /System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit
fi

#
# Operation complete!
#

echo "Reboot OS X now. Then run the Deploy.sh again to finish the installation"
exit 0
#
# Note: This "fi" is for the first "if" just to separate/make two step clear.
#
fi

#
# Finalstep.sh : lead to lid wake
#

#
# Note: Added this "if" to terminate the script if the model is 1920*1080
#
if [[ `system_profiler SPDisplaysDataType` == *"1920 x 1080"* ]]
then
echo "${BLUE}[Display]${OFF}: Resolution ${BOLD} 1920 x 1080${OFF} found"
echo "You do not need to run this script again since all the operations on your laptop have done!"
exit 0
else
#
# Detect whether the QE/CI is enabled [syscl/Yating Zhou]
#
if [[ `kextstat` == *"Azul"* && `kextstat` == *"HD5000"* ]]
then
echo "After this step finish, reboot system and enjoy your OS X! --syscl PCBeta"
esp=$(grep "dev" "${REPO}"/efi)
diskutil mount ${esp}
plist=/Volumes/EFI/EFI/CLOVER/config.plist
/usr/libexec/plistbuddy -c "Set ':Graphics:ig-platform-id' 0x0a260006" "${plist}"
if [[ `/usr/libexec/plistbuddy -c "Print"  "${plist}"` == *"ig-platform-id = 0x0a260006"* ]]
then
sudo touch /System/Library/Extensions && sudo kextcache -u /
echo "FINISH! REBOOT!"
else
echo "Failed, ensure ${esp}/EFI/CLOVER/config.plist has right config"
echo "Try the script again!"
fi
else
exit -1
fi
#
# You fool: don't use <em>rm -rf</em> commands in a script!
#
rm ${REPO}/efi
#
# Note: this "fi" is just for termiante the script one
#
fi
exit 0