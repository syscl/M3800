#!/bin/sh

#
# syscl/lighting from PCBeta
# merge for Dell Precision M3800 and XPS15 (9530)
export LC_NUMERIC="en_US.UTF-8"

# Bold / Non-bold
BOLD="\033[1m"
RED="\033[0;31m"
GREEN="\033[0;32m"
BLUE="\033[1;34m"
OFF="\033[m"

# Repository location
REPO=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Define place
decompile=${REPO}/DSDT/raw/
precompile=${REPO}/DSDT/precompile/
compile=${REPO}/DSDT/compile/
tools=${REPO}/tools/
raw=${REPO}/DSDT/raw
prepare=${REPO}/DSDT/prepare

#
# Generate define directionaries
#
if [ ! -d "${prepare}" ];then
mkdir "${prepare}"
fi

if [ ! -d "${compile}" ];then
mkdir "${compile}"
fi

#
# Define variables
# Gvariables stands for getting datas from OS X
#
gProductVersion=""
#
# Choose ESP
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
exit 0
fi
#
# Decompile dsdt
#
cd "${REPO}"

"${REPO}"/tools/iasl -w1 -da -dl "${REPO}"/DSDT/raw/DSDT.aml "${REPO}"/DSDT/raw/SSDT-*.aml

# Search specification tables

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
#"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/DSDT.dsl "${REPO}"/DSDT/patches/system/system_OSYS.txt "${REPO}"/DSDT/raw/DSDT.dsl
"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/DSDT.dsl "${REPO}"/DSDT/patches/system_OSYS.txt "${REPO}"/DSDT/raw/DSDT.dsl

echo "${BOLD}[sys] AC Adapter Fix${OFF}"
"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/DSDT.dsl "${REPO}"/DSDT/patches/system/system_ADP1.txt "${REPO}"/DSDT/raw/DSDT.dsl
#"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/DSDT.dsl "${REPO}"/DSDT/patches/system_AC.txt "${REPO}"/DSDT/raw/DSDT.dsl

echo "${BOLD}[sys] Add MCHC${OFF}"
"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/DSDT.dsl "${REPO}"/DSDT/patches/system/system_MCHC.txt "${REPO}"/DSDT/raw/DSDT.dsl

echo "${BOLD}[sys] Fix _WAK Arg0 v2${OFF}"
"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/DSDT.dsl "${REPO}"/DSDT/patches/system/system_WAK2.txt "${REPO}"/DSDT/raw/DSDT.dsl

echo "${BOLD}[sys] Add IMEI${OFF}"
"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/DSDT.dsl "${REPO}"/DSDT/patches/system/system_IMEI.txt "${REPO}"/DSDT/raw/DSDT.dsl

#echo "${BOLD}[sys] Fix PNOT/PPNT${OFF}"
#"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/DSDT.dsl "${REPO}"/DSDT/patches/system/system_PNOT.txt "${REPO}"/DSDT/raw/DSDT.dsl

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


"${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/${SaSsdt}.dsl "${REPO}"/DSDT/patches/graphics_Intel_HD4600.txt "${REPO}"/DSDT/raw/${SaSsdt}.dsl

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

${tool}iasl -vr -w1 -ve -p "${compile}"DSDT.aml "${precompile}"DSDT.dsl &> ./installation.log
${tool}iasl -vr -w1 -ve -p "${compile}"${DptfTa}.aml "${precompile}"${DptfTa}.dsl &> ./installation.log
${tool}iasl -vr -w1 -ve -p "${compile}"${SaSsdt}.aml "${precompile}"${SaSsdt}.dsl &> ./installation.log
${tool}iasl -vr -w1 -ve -p "${compile}"${SgRef}.aml "${precompile}"${SgRef}.dsl &> ./installation.log
${tool}iasl -vr -w1 -ve -p "${compile}"${OptRef}.aml "${precompile}"${OptRef}.dsl &> ./installation.log

cp "${prepare}"/*.aml "${compile}"
rm "${compile}"SSDT-*x.aml

##################################


#
# Check if Clover is in place [syscl]
#
if [ ! -d /Volumes/EFI/EFI/CLOVER ];then
#
# Not installed
#
    echo "Clover does not install on EFI, please reinstall Clover to EFI and try again."
    exit 0
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
sudo cp -r ./Kexts/audio/AppleHDA_ALC668.kext /Library/Extensions
echo "       --> ${BOLD}Installed AppleHDA_ALC668.kext to /Library/Extensions${OFF}"
sudo cp -r ./Kexts/audio/CodecCommander.kext /Library/Extensions
echo "       --> ${BOLD}Installed CodecCommander.kext to /Library/Extensions${OFF}"

#
# Patch IOKit by darkvoid
#
iokit_md5=$(md5 -q "/System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit")

echo "${GREEN}[IOKit]${OFF}: Patching IOKit for maximum pixel clock"
echo "${BLUE}[IOKit]${OFF}: Current IOKit md5 is ${BOLD}${iokit_md5}${OFF}"

case $iokit_md5 in
"2a8cbc2f6616d3f7a5e499bd2d5593ab")
echo "         --> Yosemite 10.10.1 IOKit (${GREEN}unpatched${OFF})"
sudo perl -i.bak -pe 's|\xB8\x01\x00\x00\x00\xF6\xC1\x01\x0F\x85|\x33\xC0\x90\x90\x90\x90\x90\x90\x90\xE9|sg' /System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit
sudo codesign -f -s - /System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit
echo "         Patched"
;;
"a94dc8e1b6bb6491e5f610f0a3caf960")
echo "         --> Yosemite 10.10.2 IOKit (${GREEN}unpatched${OFF})"
sudo perl -i.bak -pe 's|\xB8\x01\x00\x00\x00\xF6\xC1\x01\x0F\x85|\x33\xC0\x90\x90\x90\x90\x90\x90\x90\xE9|sg' /System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit
sudo codesign -f -s - /System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit
echo "         Patched"
;;
"29d7632362b2fa4993156717671a5642")
echo "         --> Yosemite 10.10.3 / 10.10.4 IOKit (${GREEN}unpatched${OFF})"
sudo perl -i.bak -pe 's|\xB8\x01\x00\x00\x00\xF6\xC1\x01\x0F\x85|\x33\xC0\x90\x90\x90\x90\x90\x90\x90\xE9|sg' /System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit
sudo codesign -f -s - /System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit
echo "         Patched"
;;
"15f9046ff25c807b7c76db8cdaf6ae4c")
echo "         --> El Capitan 10.11 Beta 1 IOKit (${GREEN}unpatched${OFF})"
sudo perl -i.bak -pe 's|\xB8\x01\x00\x00\x00\xF6\xC1\x01\x0F\x85|\x33\xC0\x90\x90\x90\x90\x90\x90\x90\xE9|sg' /System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit
sudo codesign -f -s - /System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit
echo "         Patched"
;;
"16e1320076417596176c919009f4b088")
echo "         --> El Capitan 10.11 Beta 2 IOKit (${GREEN}unpatched${OFF})"
sudo perl -i.bak -pe 's|\xB8\x01\x00\x00\x00\xF6\xC1\x01\x0F\x85|\x33\xC0\x90\x90\x90\x90\x90\x90\x90\xE9|sg' /System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit
sudo codesign -f -s - /System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit
echo "         Patched"
;;
"8756e20f979c9e74c80f07b452ebfadd")
echo "         --> Yosemite 10.10.1 IOKit (${RED}patched, not signed${OFF})"
;;
"20849598dcfa1e8c59038d28e0ab5fd5")
echo "         --> Yosemite 10.10.2 IOKit (${RED}patched, not signed${OFF})"
;;
"4bd81492fd13e905ef10719ef391e8a0")
echo "         --> Yosemite 10.10.3 / 10.10.4 IOKit (${RED}patched, not signed${OFF})"
;;
"1ab7c0ec047d11f6b40798b6f0107c0c")
echo "         --> El Capitan 10.11 Beta 1 IOKit (${RED}patched, not signed${OFF})"
;;
"080b614971777a0b7022f0c19ba58f9b")
echo "         --> El Capitan 10.11 Beta 2 IOKit (${RED}patched, not signed${OFF})"
;;
"f834136d72126cc9479604879270d24f")
echo "         --> Yosemite 10.10.1 IOKit (${RED}patched${OFF})"
echo "         IOKit is already patched, no action taken."
;;
"9f99c861294afc3d643987782ce45e4f")
echo "         --> Yosemite 10.10.2 IOKit (${RED}patched${OFF})"
echo "         IOKit is already patched, no action taken."
;;
"a045c1ac523fece1f1b083b2c5ee842c"|"4c99100b36f37df4bdcc5dc4cd2b8237")
echo "         --> Yosemite 10.10.3 / 10.10.4 IOKit (${RED}patched${OFF})"
echo "         IOKit is already patched, no action taken."
;;
"e96a04420555b71bb0933e26773575bc")
echo "         --> El Capitan 10.11 Beta 1 IOKit (${RED}patched${OFF})"
echo "         IOKit is already patched, no action taken."
;;
"f0b2d73ac13c9211857af8707db9676d")
echo "         --> El Capitan 10.11 Beta 1 IOKit (${RED}patched${OFF})"
echo "         IOKit is already patched, no action taken."
;;
*)
echo "         --> Unknown IOKit version (${RED}no action taken${OFF})"
;;
esac

#
# Patch end
#

echo "Rebuild caches by Kext Utility and reboot. Then run the Finalstep.sh to finish the installation"
exit