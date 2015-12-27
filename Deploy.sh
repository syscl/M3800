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
RED="\033[1;31m"
GREEN="\033[1;32m"
BLUE="\033[1;34m"
OFF="\033[m"

#
# Repository location
#
REPO=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

#
# Define place
#
decompile="${REPO}/DSDT/raw/"
precompile="${REPO}/DSDT/precompile/"
compile="${REPO}/DSDT/compile/"
tools="${REPO}/tools/"
raw="${REPO}/DSDT/raw"
prepare="${REPO}/DSDT/prepare"
#
# Define variables
# Gvariables stands for getting datas from OS X
#
gProductVersion=""

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
echo "${GREEN}[Updating]${OFF} files from ${BLUE}${target_website}${OFF}"
if [[ `curl -I -s --connect-timeout $timeout ${target_website} -w %{http_code} | grep "Status"` == *"OK"* && `curl -I -s --connect-timeout $timeout $target_website -w %{http_code} | grep "Status"` == *"200"* ]]
then
cd ${REPO}
git pull
else
echo "${RED}[Note]${OFF} ${BLUE}${target_website}${OFF} is not ${RED}available${OFF} at this time, please link ${BLUE}${target_website}${OFF} again next time."
fi

create_dir()
{
    if [ ! -d "$1" ];then
    echo "[${BLUE}Creating${OFF}] $1"
    mkdir "$1"
    fi
}

patch_acpi()
{
    echo "[${BLUE}$2${OFF}] $3"
    if [ "$2" == "syscl" ]
    then
    "${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/$1.dsl "${REPO}"/DSDT/patches/$4.txt "${REPO}"/DSDT/raw/$1.dsl
    else
    "${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/$1.dsl "${REPO}"/DSDT/patches/$2/$4.txt "${REPO}"/DSDT/raw/$1.dsl
    fi
}

compile_table()
{
    echo "[${BLUE}Compiling${OFF}] $1.dsl"
    "${REPO}"/tools/iasl -vr -w1 -ve -p "${compile}"$1.aml "${precompile}"$1.dsl
}

#
# Decide which progress to finish [syscl/Yating]
# Merge two step Initialstep.sh and Finalstep.sh into one.
#
# Note : This "if" is to make two steps clear.
#
if [ ! -f ${REPO}/DSDT/efi ];then
#
# Generate define directories.
#
create_dir "${REPO}/DSDT"
create_dir "${prepare}"
create_dir "${precompile}"
create_dir "${compile}"

#
# Choose ESP by syscl/Yating
#
diskutil list
read -p "Enter EFI's IDENTIFIER, e.g. disk0s1: " targetEFI
echo "${targetEFI}" >${REPO}/DSDT/efi
diskutil mount ${targetEFI}

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

########################
# Dsdt Patches
########################

patch_acpi DSDT syntax "Fix PARSEOP_ZERO" "fix_PARSEOP_ZERO"
patch_acpi DSDT syntax "Fix ADBG Error" "fix_ADBG"
patch_acpi DSDT graphics "Rename GFX0 to IGPU" "graphics_Rename-GFX0"
patch_acpi DSDT usb "7-series/8-series USB" "usb_7-series"
patch_acpi DSDT battery "Acer Aspire E1-571" "battery_Acer-Aspire-E1-571"
patch_acpi DSDT system "IRQ Fix" "system_IRQ"
patch_acpi DSDT system "SMBus Fix" "system_SMBUS"
patch_acpi DSDT system "OS Check Fix" "system_OSYS"
patch_acpi DSDT system "AC Adapter Fix" "system_ADP1"
patch_acpi DSDT system "Add MCHC" "system_MCHC"
patch_acpi DSDT system "Fix _WAK Arg0 v2" "system_WAK2"
patch_acpi DSDT system "Add IMEI" "system_IMEI"
patch_acpi DSDT system "Fix Non-zero Mutex" "system_Mutex"
patch_acpi DSDT misc "Add Haswell LPC" "misc_Haswell-LPC"
patch_acpi DSDT syscl "Add audio Layout 1" "audio_HDEF-layout1"
patch_acpi DSDT syscl "Rename B0D3 to HDAU" "audio_B0D3_HDAU"
patch_acpi DSDT syscl "Remove GLAN device" "remove_glan"

########################
# DptfTa Patches
########################

echo "${BLUE}[${DptfTa}]${OFF}: Patching ${DptfTa}.dsl in "${REPO}"/DSDT/raw"

patch_acpi ${DptfTa} syscl "_BST package size" "_BST-package-size"
patch_acpi ${DptfTa} graphics "Rename GFX0 to IGPU" "graphics_Rename-GFX0"

########################
# SaSsdt Patches
########################

echo "${BLUE}[${SaSsdt}]${OFF}: Patching ${SaSsdt}.dsl in "${REPO}"/DSDT/raw"

patch_acpi ${SaSsdt} graphics "Rename GFX0 to IGPU" "graphics_Rename-GFX0"
patch_acpi ${SaSsdt} syscl "Rename HD4600 to Iris Pro" "syscl_Iris_Pro"
patch_acpi ${SaSsdt} graphics "Brightness fix (Haswell)" "graphics_PNLF_haswell"
patch_acpi ${SaSsdt} syscl "Rename B0D3 to HDAU" "audio_B0D3_HDAU"
patch_acpi ${SaSsdt} syscl "Insert HDAU device" "audio_Intel_HD4600"

########################
# SgRef Patches
########################

echo "${BLUE}[${SgRef}]${OFF}: Patching SSDT-13 in "${REPO}"/DSDT/raw"

patch_acpi ${SgRef} graphics "Rename GFX0 to IGPU" "graphics_Rename-GFX0"

########################
# OptRef Patches
########################

echo "${BLUE}[${OptRef}]${OFF}: Patching SSDT-15 in "${REPO}"/DSDT/raw"

patch_acpi ${OptRef} syscl "Remove invalid operands" "WMMX-invalid-operands"
patch_acpi ${OptRef} graphics "Rename GFX0 to IGPU" "graphics_Rename-GFX0"
patch_acpi ${OptRef} syscl "Disable Nvidia card (Non-operational in OS X)" "graphics_Disable_Nvidia"

########################
# Compiling tables
########################
#
# Copying raw tables to compile.
#
echo "${BLUE}[Copying]${OFF}: raw/untouch tables to compile..."
cp "${raw}"/SSDT-*.aml "$compile"

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

#
# Copying all tables to precompile.
#
echo "${BLUE}[Copying]${OFF}: all tables to precompile..."
cp "${raw}/"*.dsl "${precompile}"

########################
# Compiling tables
########################

compile_table "DSDT"
compile_table "${DptfTa}"
compile_table "${SaSsdt}"
compile_table "${SgRef}"
compile_table "${OptRef}"

#
# Clean up dynamic SSDTs.
#
echo "[${GREEN}Cleaning${OFF}]: dynamic SSDTs..."
rm "${compile}"SSDT-*x.aml

##################################


#
# Check if Clover is in place [syscl/Yating Zhou]
#
if [ ! -d /Volumes/EFI/EFI/CLOVER ];then
#
# Not installed
#
    echo "[${RED}NOTE${OFF}] Clover does not install on EFI, please reinstall Clover to EFI and try again."
# ERROR.
#
# Note: The exit value can be anything between 0 and 255 and thus -1 is actually 255
#       but we use -1 here to make it clear (obviously) that something went wrong.
#
exit -1
fi

create_dir "/Volumes/EFI/EFI/CLOVER/ACPI/patched"

#
# Copy AML to Destination Place
#

cp "${compile}"*.aml /Volumes/EFI/EFI/CLOVER/ACPI/patched

#
# Gain OS generation
#
gProductVersion="$(sw_vers -productVersion)"
OS_Version=$(echo ${gProductVersion:0:5})
KEXT_DIR=/Volumes/EFI/EFI/CLOVER/kexts/${OS_Version}
#
# Updating kexts. NOTE: This progress will remove any previous kexts.
#
echo "\n"
echo "[${GREEN}Updating${OFF}] kexts from ${target_website}"
rm -R ${KEXT_DIR}
cp -R ./CLOVER/kexts/${OS_Version} /Volumes/EFI/EFI/CLOVER/kexts/
ls ./Kexts |grep "kext" |xargs -I{} cp -R ./Kexts/{} ${KEXT_DIR}/

#
# Finish operation of configuration on booting progress [syscl/Yating Zhou]
#

#
# Install AppleHDA by darkvoid
#
echo "[${GREEN}Creating${OFF}] AppleHDA injection kernel extension for ${BOLD}ALC668${OFF}"
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
echo "[${BLUE}Repairing${OFF}] kexts permission..."
sudo chmod -R 755 /Library/Extensions/AppleHDA_ALC668.kext
sudo chown -R root:wheel /Library/Extensions/AppleHDA_ALC668.kext
sudo chmod -R 755 /Library/Extensions/CodecCommander.kext
sudo chown -R root:wheel /Library/Extensions/CodecCommander.kext
sudo touch /System/Library/Extensions && sudo kextcache -u /
#
# Check if your resolution is 1920*1080 or 3200 x 1800 by syscl/Yating Zhou.
# Note: You need to change System Agent (SA) Configuration—>Graphics Configuration->DVMT Pre-Allocated->『128MB』
#
echo "[${RED}NOTE${OFF}] You need to change ${BOLD} System Agent (SA) Configuration—>Graphics Configuration->DVMT Pre-Allocated->${RED} ${BOLD}『128MB』${OFF}"
if [[ `system_profiler SPDisplaysDataType` == *"1920 x 1080"* ]]
then
echo "[${BLUE}Display${OFF}]: Resolution ${BOLD} 1920 x 1080${OFF} found"
echo "Updating configuration for 1920 x 1080p model, progress will finish instantly..."
cp ./CLOVER/1920x1080_config.plist /Volumes/EFI/EFI/CLOVER/config.plist
#
# You fool: don't use <em>rm -rf</em> commands in a script!
#
rm ${REPO}/DSDT/efi
echo "Congratulations! All operation has been completed! Reboot now. Then enjoy your OS X! --syscl PCBeta"
else
echo "[${BLUE}Display${OFF}]: Resolution ${BOLD} 3200 x 1800${OFF} found"
#
# Patch IOKit.
#
echo "[${BLUE}Patching${OFF}] IOKit for maximum pixel clock"
sudo perl -i.bak -pe 's|\xB8\x01\x00\x00\x00\xF6\xC1\x01\x0F\x85|\x33\xC0\x90\x90\x90\x90\x90\x90\x90\xE9|sg' /System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit
sudo codesign -f -s - /System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit
echo "[${RED}NOTE${OFF}]Reboot! Then run the Deploy.sh ${RED}AGAIN${OFF} to finish the installation."
fi

#
# Operation complete!
#

#
# Note: This "else" is for the first "if" just to separate/make two step clear.
#
else

#
# Finalstep.sh : lead to lid wake
#

#
# Note: Added this "if" to terminate the script if the model is 1920*1080
#
if [[ `system_profiler SPDisplaysDataType` == *"1920 x 1080"* ]]
then
echo "[${BLUE}Display${OFF}]: Resolution ${BOLD} 1920 x 1080${OFF} found"
echo "[${RED}NOTE${OFF}]You do not need to run this script again since all the operations on your laptop have done!"
else
#
# Detect whether the QE/CI is enabled [syscl/Yating Zhou]
#
if [[ `kextstat` == *"Azul"* && `kextstat` == *"HD5000"* ]]
then
echo "After this step finish, reboot system and enjoy your OS X! --syscl PCBeta"
diskutil mount `grep "disk" ./DSDT/efi`
plist=/Volumes/EFI/EFI/CLOVER/config.plist
/usr/libexec/plistbuddy -c "Set ':Graphics:ig-platform-id' 0x0a260006" "${plist}"
if [[ `/usr/libexec/plistbuddy -c "Print"  "${plist}"` == *"ig-platform-id = 0x0a260006"* ]]
then
sudo touch /System/Library/Extensions && sudo kextcache -u /
echo "[${RED}NOTE${OFF}]FINISH! REBOOT!"
else
echo "Failed, ensure /Volumes/EFI/EFI/CLOVER/config.plist has right config"
echo "Try the script again!"
fi
else
echo "[${RED}NOTE${OFF}] It seems that QE/EC has not been powered up yet."
exit -1
#
fi
#
# You fool: don't use <em>rm -rf</em> commands in a script!
#
rm ${REPO}/DSDT/efi
#
# Note: this "fi" is just for 1920 x 1080p one
#
fi
#
# Note: this "fi" is just to terminate the whole "if".
#
fi
exit 0