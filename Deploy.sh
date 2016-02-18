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
plist="${REPO}/Kexts/audio/AppleHDA_ALC668.kext/Contents/Info.plist"
config_plist="/Volumes/EFI/EFI/CLOVER/config.plist"
EFI_INFO="${REPO}/DSDT/EFIINFO"

#
# Define variables
# Gvariables stands for getting datas from OS X
#
gProductVersion=""
target_website=""
target_website_status=""
RETURN_VAL=""
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
echo "[ ${GREEN}--->${OFF} ] Updating files from ${BLUE}${target_website}...${OFF}"
target_website_status=`curl -I -s --connect-timeout $timeout ${target_website} -w %{http_code}`
if [[ `echo ${target_website_status} |grep -i "Status"` == *"OK"* && `echo ${target_website_status} |grep -i "Status"` == *"200"* ]]
then
cd ${REPO}
git pull
else
echo "[ ${RED}Note${OFF} ] ${BLUE}${target_website}${OFF} is not ${RED}available${OFF} at this time, please link ${BLUE}${target_website}${OFF} again next time."
fi

locate_esp(){
    diskutil info $1 |grep -i "Partition UUID" >${EFI_INFO}
    targetUUID=$(grep -i "Disk / Partition UUID" ${EFI_INFO} |awk -F':' '{print $2}')
}

create_dir()
{
    if [ ! -d "$1" ];then
    echo "${BLUE}[Creating directory]${OFF}: $1"
    mkdir "$1"
    fi
}

patch_acpi()
{
    if [ "$2" == "syscl" ]
    then
    "${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/$1.dsl "${REPO}"/DSDT/patches/$3.txt "${REPO}"/DSDT/raw/$1.dsl
    else
    "${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/$1.dsl "${REPO}"/DSDT/patches/$2/$3.txt "${REPO}"/DSDT/raw/$1.dsl
    fi
}

tidy_execute()
{
    $1 >./DSDT/report 2>&1 && RETURN_VAL=0 || RETURN_VAL=1
#
# -------------------------------:----------------------------------------:---------------------------:---------------------------------:----------------------------------
#  grep -i "Error" ./DSDT/report : grep -i "patch complete" ./DSDT/report : ! `test -s ./DSDT/report` : grep -i "mounted" ./DSDT/report : grep -i "complete" ./DSDT/report
# -------------------------------:----------------------------------------:---------------------------:---------------------------------:----------------------------------
#  iasl failure                  : patchmatic failure                     : cp, rm, grep, touch, mk...: diskutil mount                  : codesign status
# -------------------------------:----------------------------------------:---------------------------:---------------------------------:----------------------------------
#
#    if [[ `grep -i "0 Errors" ./DSDT/report` || `grep -i "patch complete" ./DSDT/report` || ! `test -s ./DSDT/report` || `grep -i "mounted" ./DSDT/report` || `grep -i "complete" ./DSDT/report` ]]
#    then
#        echo "[  ${GREEN}OK${OFF}  ] $2."
#    else
#    echo "[${RED}FAILED${OFF}] $2."
#    grep -i -E "Error    |patchmatic|cp" ./DSDT/report >./DSDT/report.tmp
#    cat ./DSDT/report.tmp
#    fi
#

    if [ "${RETURN_VAL}" == 0 ]
    then
        echo "[  ${GREEN}OK${OFF}  ] $2."
    else
        echo "[${RED}FAILED${OFF}] $2."
        grep -i -E "Error    |patchmatic|cp|rm" ./DSDT/report >./DSDT/report.tmp
        cat ./DSDT/report.tmp
    fi
    rm ./DSDT/report.tmp ./DSDT/report &> /dev/null
}

compile_table()
{
    echo "${BLUE}[Compiling]${OFF}: $1.dsl"
    "${REPO}"/tools/iasl -vr -w1 -ve -p "${compile}"$1.aml "${precompile}"$1.dsl
}

rebuild_kernel_cache()
{
#
# Repair the permission by syscl/Yating Zhou
#
    if [ "$1" == *"force"* ]
    then
    ls /System/Library/Extensions |xargs -I{} sudo chmod -R 755 /System/Library/Extensions/{}
    ls /System/Library/Extensions |xargs -I{} sudo chown -R root:wheel /System/Library/Extensions/{}
    ls /Library/Extensions |xargs -I{} sudo chmod -R 755 /Library/Extensions/{}
    ls /Library/Extensions |xargs -I{} sudo chown -R root:wheel /Library/Extensions/{}
    fi

    if [ "$1" == *"hda"* ]
    then
    sudo chmod -R 755 /Library/Extensions/AppleHDA_ALC668.kext
    sudo chown -R root:wheel /Library/Extensions/AppleHDA_ALC668.kext
    sudo chmod -R 755 /Library/Extensions/CodecCommander.kext
    sudo chown -R root:wheel /Library/Extensions/CodecCommander.kext
    fi

    sudo touch /System/Library/Extensions
    sudo /bin/kill -1 `ps -ax | awk '{print $1" "$5}' | grep kextd | awk '{print $1}'`
    sudo kextcache -u /
}

install_audio()
{
    rm -rf ./Kexts/audio/AppleHDA_ALC668.kext 2&>/dev/null
    cp -R /System/Library/Extensions/AppleHDA.kext ./Kexts/audio/AppleHDA_ALC668.kext
    rm -rf ./Kexts/audio/AppleHDA_ALC668.kext/Contents/Resources/*
    rm -rf ./Kexts/audio/AppleHDA_ALC668.kext/Contents/PlugIns
    rm -rf ./Kexts/audio/AppleHDA_ALC668.kext/Contents/_CodeSignature
    rm -rf ./Kexts/audio/AppleHDA_ALC668.kext/Contents/MacOS/AppleHDA
    rm ./Kexts/audio/AppleHDA_ALC668.kext/Contents/version.plist
    ln -s /System/Library/Extensions/AppleHDA.kext/Contents/MacOS/AppleHDA ./Kexts/audio/AppleHDA_ALC668.kext/Contents/MacOS/AppleHDA
    cp ./Kexts/audio/*.zlib ./Kexts/audio/AppleHDA_ALC668.kext/Contents/Resources/
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
    /usr/libexec/plistbuddy -c "Add ':IOKitPersonalities:HDA Hardware Config Resource: IOProbeScore' integer" $plist
    /usr/libexec/plistbuddy -c "Set ':IOKitPersonalities:HDA Hardware Config Resource:IOProbeScore' 2000" $plist
    /usr/libexec/plistbuddy -c "Merge ./Kexts/audio/ahhcd.plist ':IOKitPersonalities:HDA Hardware Config Resource'" $plist
    sudo cp -R ./Kexts/audio/AppleHDA_ALC668.kext /Library/Extensions
    sudo cp -R ./Kexts/audio/CodecCommander.kext /Library/Extensions
}

#
# Decide which progress to finish [syscl/Yating]
# Merge two step Initialstep.sh and Finalstep.sh into one.
#
# Note : This "if" is to make two steps clear.
#
if [ ! -f ${EFI_INFO} ];then
########################
# Generate define directionaries
########################

tidy_execute "create_dir "${REPO}/DSDT"" "Create ./DSDT"
tidy_execute "create_dir "${prepare}"" "Create ./DSDT/prepare"
tidy_execute "create_dir "${precompile}"" "Create ./DSDT/precompile"
tidy_execute "create_dir "${compile}"" "Create ./DSDT/compile"

########################
# Choose ESP by syscl/Yating
########################

diskutil list
read -p "Enter EFI's IDENTIFIER, e.g. disk0s1: " targetEFI
locate_esp ${targetEFI}
tidy_execute "diskutil mount ${targetEFI}" "Mount ${targetEFI}"

#
# Ensure / Force Graphics card to power
#
if [[ `system_profiler SPDisplaysDataType` == *"1920 x 1080"* ]]
then
    /usr/libexec/plistbuddy -c "Set ':Graphics:ig-platform-id' 0x0a260006" "${config_plist}"
else
    /usr/libexec/plistbuddy -c "Set ':Graphics:ig-platform-id' 0x0a2e0008" "${config_plist}"
    if [[ `/usr/libexec/plistbuddy -c "Print"  "${config_plist}"` == *"ig-platform-id = 0x0a2e0008"* ]]
    then
    echo "[  ${GREEN}OK${OFF}  ] Force Graphics card to power(Second stage will lead the lid wake) by syscl/Lighting/Yating Zhou."
    fi
fi

########################
# Copy origin aml to raw
########################

if [ -f /Volumes/EFI/EFI/CLOVER/ACPI/origin/DSDT.aml ];then
tidy_execute "cp /Volumes/EFI/EFI/CLOVER/ACPI/origin/DSDT.aml /Volumes/EFI/EFI/CLOVER/ACPI/origin/SSDT-*.aml "${decompile}"" "Copy untouch ACPI tables"
else
echo "[ ${RED}NOTE${OFF} ] Warning!! DSDT and SSDTs doesn't exist! Press Fn+F4 under Clover to dump ACPI tables"
# ERROR.
#
# Note: The exit value can be anything between 0 and 255 and thus -1 is actually 255
#       but we use -1 here to make it clear (obviously) that something went wrong.
#
exit -1
fi

########################
# Decompile dsdt
########################

cd "${REPO}"
echo "[ ${GREEN}--->${OFF} ] ${BLUE}Disassembling tables...${OFF}"
tidy_execute ""${REPO}"/tools/iasl -w1 -da -dl "${REPO}"/DSDT/raw/DSDT.aml "${REPO}"/DSDT/raw/SSDT-*.aml" "Disassemble tables"

########################
# Search specification tables by syscl/Yating Zhou
########################

########################
# Search DptfTa
########################

for num in $(seq 1 20)
do
grep -i "DptfTa" "${REPO}"/DSDT/raw/SSDT-${num}.dsl &> /dev/null && RETURN_VAL=0 || RETURN_VAL=1
if [ "${RETURN_VAL}" == 0 ];then
DptfTa=SSDT-$num
fi
done

########################
# Search SaSSDT
########################

for num in $(seq 1 20)
do
grep -i "SaSsdt" "${REPO}"/DSDT/raw/SSDT-${num}.dsl &> /dev/null && RETURN_VAL=0 || RETURN_VAL=1
if [ "${RETURN_VAL}" == 0 ];then
SaSsdt=SSDT-$num
fi
done

########################
# Search SgRef
########################

for num in $(seq 1 20)
do
grep -i "SgRef" "${REPO}"/DSDT/raw/SSDT-${num}.dsl &> /dev/null && RETURN_VAL=0 || RETURN_VAL=1
if [ "${RETURN_VAL}" == 0 ];then
SgRef=SSDT-$num
fi
done

########################
# Search OptRef
########################

for num in $(seq 1 20)
do
grep -i "OptRef" "${REPO}"/DSDT/raw/SSDT-${num}.dsl &> /dev/null && RETURN_VAL=0 || RETURN_VAL=1
if [ "${RETURN_VAL}" == 0 ];then
OptRef=SSDT-$num
fi
done

########################
# DSDT Patches
########################

echo "[ ${GREEN}--->${OFF} ] ${BLUE}Patching DSDT.dsl${OFF}"
tidy_execute "patch_acpi DSDT syntax "fix_PARSEOP_ZERO"" "Fix PARSEOP_ZERO"
tidy_execute "patch_acpi DSDT syntax "fix_ADBG"" "Fix ADBG Error"
# patch_acpi DSDT syscl "Insert_DTGP"
tidy_execute "patch_acpi DSDT graphics "graphics_Rename-GFX0"" "Rename GFX0 to IGPU"
tidy_execute "patch_acpi DSDT usb "usb_7-series"" "7-series/8-series USB"
tidy_execute "patch_acpi DSDT usb "usb_prw_0x0d_xhc"" "Fix USB _PRW"
# patch_acpi DSDT usb "usb_8-series_prw"
tidy_execute "patch_acpi DSDT battery "battery_Acer-Aspire-E1-571"" "Acer Aspire E1-571"
tidy_execute "patch_acpi DSDT system "system_IRQ"" "IRQ Fix"
tidy_execute "patch_acpi DSDT system "system_SMBUS"" "SMBus Fix"
tidy_execute "patch_acpi DSDT system "system_ADP1"" "AC Adapter Fix"
tidy_execute "patch_acpi DSDT system "system_MCHC"" "Add MCHC"
tidy_execute "patch_acpi DSDT system "system_WAK2"" "Fix _WAK Arg0 v2"
tidy_execute "patch_acpi DSDT system "system_IMEI"" "Add IMEI"
tidy_execute "patch_acpi DSDT system "system_Mutex"" "Fix Non-zero Mutex"
# tidy_execute "patch_acpi DSDT misc "misc_Haswell-LPC"" "Add HM87 LPC (8086:8c4b)"
tidy_execute "patch_acpi DSDT syscl "system_OSYS"" "OS Check Fix"
tidy_execute "patch_acpi DSDT syscl "audio_HDEF-layout1"" "Add audio Layout 1"
tidy_execute "patch_acpi DSDT syscl "audio_B0D3_HDAU"" "Rename B0D3 to HDAU"
tidy_execute "patch_acpi DSDT syscl "remove_glan"" "Remove GLAN device"

########################
# DptfTa Patches
########################

echo "[ ${GREEN}--->${OFF} ] ${BLUE}Patching ${DptfTa}.dsl${OFF}"
tidy_execute "patch_acpi ${DptfTa} syscl "_BST-package-size"" "_BST package size"
tidy_execute "patch_acpi ${DptfTa} graphics "graphics_Rename-GFX0"" "Rename GFX0 to IGPU"

########################
# SaSsdt Patches
########################

echo "[ ${GREEN}--->${OFF} ] ${BLUE}Patching ${SaSsdt}.dsl${OFF}"
tidy_execute "patch_acpi ${SaSsdt} graphics "graphics_Rename-GFX0"" "Rename GFX0 to IGPU"
tidy_execute "patch_acpi ${SaSsdt} syscl "syscl_Iris_Pro"" "Rename HD4600 to Iris Pro"
tidy_execute "patch_acpi ${SaSsdt} graphics "graphics_PNLF_haswell"" "Brightness fix (Haswell)"
tidy_execute "patch_acpi ${SaSsdt} syscl "audio_B0D3_HDAU"" "Rename B0D3 to HDAU"
tidy_execute "patch_acpi ${SaSsdt} syscl "audio_Intel_HD4600"" "Insert HDAU device"

########################
# SgRef Patches
########################

echo "[ ${GREEN}--->${OFF} ] ${BLUE}Patching ${SgRef}.dsl${OFF}"
tidy_execute "patch_acpi ${SgRef} graphics "graphics_Rename-GFX0"" "Rename GFX0 to IGPU"

########################
# OptRef Patches
########################

echo "[ ${GREEN}--->${OFF} ] ${BLUE}Patching ${OptRef}.dsl${OFF}"
tidy_execute "patch_acpi ${OptRef} syscl "WMMX-invalid-operands"" "Remove invalid operands"
tidy_execute "patch_acpi ${OptRef} graphics "graphics_Rename-GFX0"" "Rename GFX0 to IGPU"
tidy_execute "patch_acpi ${OptRef} syscl "graphics_Disable_Nvidia"" "Disable Nvidia card (Non-operational in OS X)"

########################
# Copying all tables to precompile.
########################

echo "[ ${GREEN}--->${OFF} ] ${BLUE}Copying tables to precompile...${OFF}"
tidy_execute "cp "${raw}/"*.dsl "${precompile}"" "Copy tables to precompile"

########################
# Copying raw tables to compile.
########################

echo "[ ${GREEN}--->${OFF} ] ${BLUE}Copying untouched tables to ./DSDT/compile...${OFF}"
tidy_execute "cp "${raw}"/SSDT-*.aml "$compile"" "Copy untouched tables to ./DSDT/compile"


########################
# Compiling tables
########################

echo "[ ${GREEN}--->${OFF} ] ${BLUE}Compiling tables...${OFF}"
tidy_execute "compile_table "DSDT"" "Compiling DSDT"
tidy_execute "compile_table "${DptfTa}"" "Compile DptfTa"
tidy_execute "compile_table "${SaSsdt}"" "Compile SaSsdt"
tidy_execute "compile_table "${SgRef}"" "Compile SgRef"
tidy_execute "compile_table "${OptRef}"" "Compile OptRef"

########################
# Copying SSDT-rmne.aml.
########################

echo "[ ${GREEN}--->${OFF} ] ${BLUE}Copying SSDT-rmne.aml to ./DSDT/compile...${OFF}"
tidy_execute "cp "${prepare}"/SSDT-rmne.aml "${compile}"" "Copy SSDT-rmne.aml to ./DSDT/compile"

########################
# Detect which SSDT for processor to be installed.
########################

if [[ `sysctl machdep.cpu.brand_string` == *"i7-4702HQ"* ]]
then
tidy_execute "cp "${prepare}"/CpuPm-4702HQ.aml "${compile}"/SSDT-pr.aml" "Generate C-States and P-State for Intel ${BLUE}i7-4702HQ${OFF}"
fi

if [[ `sysctl machdep.cpu.brand_string` == *"i7-4712HQ"* ]]
then
tidy_execute "cp "${prepare}"/CpuPm-4712HQ.aml "${compile}"/SSDT-pr.aml" "Generate C-States and P-State for Intel ${BLUE}i7-4712HQ${OFF}"
fi

########################
# Clean up dynamic SSDTs.
########################

tidy_execute "rm "${compile}"SSDT-*x.aml" "Clean dynamic SSDTs"

########################


########################
# Check if Clover is in place [syscl/Yating Zhou]
########################

if [ ! -d /Volumes/EFI/EFI/CLOVER ];then
#
# Not installed
#
    echo "[ ${RED}NOTE${OFF} ] Clover does not install on EFI, please reinstall Clover to EFI and try again."
# ERROR.
#
# Note: The exit value can be anything between 0 and 255 and thus -1 is actually 255
#       but we use -1 here to make it clear (obviously) that something went wrong.
#
exit -1
fi

tidy_execute "create_dir "/Volumes/EFI/EFI/CLOVER/ACPI/patched"" "Create /Volumes/EFI/EFI/CLOVER/ACPI/patched"

########################
# Copy AML to Destination Place
########################

tidy_execute "cp "${compile}"*.aml /Volumes/EFI/EFI/CLOVER/ACPI/patched" "Copy tables to /Volumes/EFI/EFI/CLOVER/ACPI/patched"

########################
# Gain OS generation
########################

gProductVersion="$(sw_vers -productVersion)"
OS_Version=$(echo ${gProductVersion:0:5})
KEXT_DIR=/Volumes/EFI/EFI/CLOVER/kexts/${OS_Version}

########################
# Updating kexts. NOTE: This progress will remove any previous kexts.
########################

echo "[ ${GREEN}--->${OFF} ] ${BLUE}Updating kexts...${OFF}"
tidy_execute "rm -rf ${KEXT_DIR}" "Remove pervious kexts in ${KEXT_DIR}"
tidy_execute "cp -R ./CLOVER/kexts/${OS_Version} /Volumes/EFI/EFI/CLOVER/kexts/" "Update kexts from ./CLOVER/kexts/${OS_Version}"
tidy_execute "cp -R ./Kexts/*.kext ${KEXT_DIR}/" "Update kexts from ./Kexts"

#
# Finish operation of configuration on booting progress [syscl/Yating Zhou]
#

########################
# Installing audio
########################

echo "[ ${GREEN}--->${OFF} ] ${BLUE}Installing audio...${OFF}"
tidy_execute "install_audio" "Install audio"

########################
# Rebuilding kernel extensions cache.
########################

echo "[ ${GREEN}--->${OFF} ] ${BLUE}Rebuilding kernel extensions cache...${OFF}"
tidy_execute "rebuild_kernel_cache "hda"" "Rebuild kernel extensions cache"

#
# Check if your resolution is 1920*1080 or 3200 x 1800 by syscl/Yating Zhou.
# Note: You need to change System Agent (SA) Configuration—>Graphics Configuration->DVMT Pre-Allocated->『128MB』
#
echo "[ ${RED}NOTE${OFF} ] You need to change ${BOLD}System Agent (SA) Configuration—>Graphics Configuration->DVMT Pre-Allocated->${RED}『128MB』${OFF}"
if [[ `system_profiler SPDisplaysDataType` == *"1920 x 1080"* ]]
then
echo "[ ${GREEN}--->${OFF} ] ${BLUE}Updating configuration for 1920 x 1080p model, progress will finish instantly...${OFF}"
tidy_execute "cp ./CLOVER/1920x1080_config.plist ${config_plist}" "Update configuration for 1920 x 1080p model"
#
# You fool: don't use <em>rm -rf</em> commands in a script!
#
tidy_execute "rm ${EFI_INFO}" "Clean up after installation"
echo "Congratulations! All operation has been completed! Reboot now. Then enjoy your OS X! --syscl PCBeta"
else
echo "[ ${GREEN}--->${OFF} ] ${BLUE}Updating configuration for 3200 x 1800 model, progress will finish instantly...${OFF}"
#
# Patch IOKit.
#
echo "[ ${GREEN}--->${OFF} ] ${BLUE}Patching IOKit for maximum pixel clock...${OFF}"
sudo perl -i.bak -pe 's|\xB8\x01\x00\x00\x00\xF6\xC1\x01\x0F\x85|\x33\xC0\x90\x90\x90\x90\x90\x90\x90\xE9|sg' /System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit
tidy_execute "sudo codesign -f -s - /System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit" "Sign /System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit"
echo "[ ${RED}NOTE${OFF} ] ${RED}REBOOT${OFF}! Then run the Deploy.sh ${RED}AGAIN${OFF} to finish the installation."
fi

########################
# Operation complete!
########################

#
# Note: This "else" is for the first "if" just to separate/make two step clear.
#
else

########################
# Finalstep.sh : lead to lid wake
########################

#
# Note: Added this "if" to terminate the script if the model is 1920*1080
#
if [[ `system_profiler SPDisplaysDataType` == *"1920 x 1080"* ]]
then
echo "[ ${RED}NOTE${OFF} ] You do not need to run this script again since all the operations on your laptop have done!"
else

########################
# Detect whether the QE/CI is enabled [syscl/Yating Zhou]
########################

if [[ `kextstat` == *"Azul"* && `kextstat` == *"HD5000"* ]]
then
echo "[ ${RED}NOTE${OFF} ] After this step finish, reboot system and enjoy your OS X! --syscl PCBeta"
targetUUID=$(grep -i "Disk / Partition UUID" ${EFI_INFO} |awk -F':' '{print $2}')
tidy_execute "diskutil mount ${targetUUID}" "Mount ${targetUUID}"
tidy_execute "rm /Volumes/EFI/EFI/CLOVER/1920x1080_config.plist" "Remove redundant plist"

########################
# Lead to lid wake by syscl/Yating Zhou
########################

echo "[ ${GREEN}--->${OFF} ] ${BLUE}Rebuilding kernel extensions cache...${OFF}"
tidy_execute "rebuild_kernel_cache "force"" "Rebuild kernel extensions cache"
echo "[ ${GREEN}--->${OFF} ] ${BLUE}Leading to lid wake by syscl/Lighting/Yating Zhou ...${OFF}"
/usr/libexec/plistbuddy -c "Set ':Graphics:ig-platform-id' 0x0a260006" "${config_plist}"

if [[ `/usr/libexec/plistbuddy -c "Print"  "${config_plist}"` == *"ig-platform-id = 0x0a260006"* ]]
then

echo "[  ${GREEN}OK${OFF}  ] Lead to lid wake by syscl/Lighting/Yating Zhou."
########################
# Rebuilding kernel extensions cache.
########################

echo "[ ${GREEN}--->${OFF} ] ${BLUE}Rebuilding kernel extensions cache...${OFF}"
tidy_execute "rebuild_kernel_cache "force"" "Rebuild kernel extensions cache"
echo "[ ${RED}NOTE${OFF} ] FINISH! ${RED}REBOOT${OFF}!"
else
echo "[${RED}FAILED${OFF}] Ensure ${config_plist} has right config."
echo "[ ${RED}NOTE${OFF} ] Try the script again!"
fi
else
echo "[ ${RED}NOTE${OFF} ] It seems that QE/EC has not been powered up yet."
exit -1
#
fi
#
# You fool: don't use <em>rm -rf</em> commands in a script!
#
tidy_execute "rm ${EFI_INFO}" "Clean up after installation"
#
# Note: this "fi" is just for 1920 x 1080p one
#
fi
#
# Note: this "fi" is just to terminate the whole "if".
#
fi
exit 0