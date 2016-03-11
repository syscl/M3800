#!/bin/sh

#
# syscl/Yating Zhou/lighting from bbs.PCBeta.com
# Merge for Dell Precision M3800 and XPS15 (9530).
#
export LC_NUMERIC="en_US.UTF-8"

#
# Prevent non-printable/control characters.
#
unset GREP_OPTIONS
unset GREP_COLORS
unset GREP_COLOR

#
# Display style setting.
#
BOLD="\033[1m"
RED="\033[1;31m"
GREEN="\033[1;32m"
BLUE="\033[1;34m"
OFF="\033[m"

#
# Located repository.
#
REPO=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

#
# Path and filename setup.
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
patch_config_plist="${REPO}/DSDT/tmp.plist"

#
# Define variables.
#
# Gvariables stands for getting datas from OS X.
#
gProductVersion=""
target_website=""
target_website_status=""
RETURN_VAL=""
gEDID=""
gHorizontalRez_pr=""
gHorizontalRez_st=""
gHorizontalRez=""
gVerticalRez_pr=""
gVerticalRez_st=""
gVerticalRez=""
gSystemRez=""
gSystemHorizontalRez=""
gSystemVerticalRez=""
gPatchIOKit=0
gClover_ig_platform_id=""
target_ig_platform_id=""
find_lid_byte_ENCODE=""
replace_lid_byte_ENCODE=""
replace_framebuffer_data_byte=""
replace_framebuffer_data_byte_ENCODE=""
find_hdmi_bytes=""
replace_hdmi_bytes=""
find_hdmi_bytes_ENCODE=""
replace_hdmi_bytes_ENCODE=""
find_Azul_data=""
replace_Azul_data=""
find_Azul_data_ENCODE=""
replace_Azul_data_ENCODE=""

#
# Define target website
#
target_website=https://github.com/syscl/M3800

#
#--------------------------------------------------------------------------------
#

function _PRINT_MSG()
{
    local message=$1

    if [[ $message =~ 'OK' ]];
      then
        local message=$(echo $message | sed -e 's/.*OK://')
        echo "[  ${GREEN}OK${OFF}  ] ${message}."
      else
        if [[ $message =~ 'FAILED' ]];
          then
            local message=$(echo $message | sed -e 's/.*://')
            echo "[${RED}FAILED${OFF}] ${message}."
          else
            if [[ $message =~ '--->' ]];
              then
                local message=$(echo $message | sed -e 's/.*--->://')
                echo "[ ${GREEN}--->${OFF} ] ${message}"
              else
                if [[ $message =~ 'NOTE' ]];
                  then
                    local message=$(echo $message | sed -e 's/.*NOTE://')
                    echo "[ ${RED}Note${OFF} ] ${message}."
                fi
            fi
        fi
    fi
}

#
#--------------------------------------------------------------------------------
#

function _update()
{
    #
    # Sync all files from https://github.com/syscl/M3800
    #
    # Check if github is available
    #
    local timeout=5

    #
    # Detect whether the website is available
    #
    _PRINT_MSG "--->: Updating files from ${BLUE}${target_website}...${OFF}"
    target_website_status=`curl -I -s --connect-timeout $timeout ${target_website} -w %{http_code}`
    if [[ `echo ${target_website_status} | grep -i "Status"` == *"OK"* && `echo ${target_website_status} | grep -i "Status"` == *"200"* ]]
      then
        cd ${REPO}
        git pull
      else
        _PRINT_MSG "NOTE: ${BLUE}${target_website}${OFF} is not ${RED}available${OFF} at this time, please link ${BLUE}${target_website}${OFF} again next time."
    fi
}

#
#--------------------------------------------------------------------------------
#

function locate_esp()
{
    diskutil info $1 | grep -i "Partition UUID" >${EFI_INFO}
    targetUUID=$(grep -i "Disk / Partition UUID" ${EFI_INFO} | awk -F':' '{print $2}')
}

#
#--------------------------------------------------------------------------------
#

function create_dir()
{
    if [ ! -d "$1" ];
      then
        mkdir "$1"
    fi
}

#
#--------------------------------------------------------------------------------
#

function patch_acpi()
{
    if [ "$2" == "syscl" ];
      then
        "${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/$1.dsl "${REPO}"/DSDT/patches/$3.txt "${REPO}"/DSDT/raw/$1.dsl
      else
        "${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/$1.dsl "${REPO}"/DSDT/patches/$2/$3.txt "${REPO}"/DSDT/raw/$1.dsl
    fi
}

#
#--------------------------------------------------------------------------------
#

function tidy_execute()
{
    #
    # Make the output clear.
    #
    $1 >./DSDT/report 2>&1 && RETURN_VAL=0 || RETURN_VAL=1

    if [ "${RETURN_VAL}" == 0 ];
      then
        _PRINT_MSG "OK: $2"
      else
        _PRINT_MSG "FAILED: $2"
        cat ./DSDT/report
    fi

    rm ./DSDT/report &> /dev/null
}

#
#--------------------------------------------------------------------------------
#

function compile_table()
{
    "${REPO}"/tools/iasl -vr -w1 -ve -p "${compile}"$1.aml "${precompile}"$1.dsl
}

#
#--------------------------------------------------------------------------------
#

function rebuild_kernel_cache()
{
    #
    # Repair the permission & refresh kernelcache.
    #
    sudo touch /System/Library/Extensions
    sudo /bin/kill -1 `ps -ax | awk '{print $1" "$5}' | grep kextd | awk '{print $1}'`
    sudo kextcache -u /
}

#
#--------------------------------------------------------------------------------
#

function install_audio()
{
    #
    # Generate audio from current system.
    #
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
#--------------------------------------------------------------------------------
#

function _initIntel()
{
    if [[ `/usr/libexec/plistbuddy -c "Print"  "${config_plist}"` == *"Intel = false"* ]];
      then
        /usr/libexec/plistbuddy -c "Set ':Graphics:Inject:Intel' true" "${config_plist}"
    fi
}

#
#--------------------------------------------------------------------------------
#

function _getEDID()
{
    #
    # Whether the Intel Graphics kernel extensions are loaded in cache?
    #
    if [[ `kextstat` == *"Azul"* && `kextstat` == *"HD5000"* ]];
      then
        #
        # Yes. Then we can directly assess EDID from ioreg.
        #
        # Get raw EDID.
        #
        gEDID=$(ioreg -lw0 | grep -i "IODisplayEDID" | sed -e 's/.*<//' -e 's/>//')

        #
        # Get native resolution(Rez) from $gEDID.
        #
        # Get horizontal resolution.
        #
        gHorizontalRez_pr=$(echo $gEDID | cut -c 117)
        gHorizontalRez_st=$(echo $gEDID | cut -c 113-114)
        gHorizontalRez=$((0x$gHorizontalRez_pr$gHorizontalRez_st))

        #
        # Get vertical resolution. Actually, Vertical rez is no more needed in this scenario, but we just use this to make the
        # progress clear.
        #
        gVerticalRez_pr=$(echo $gEDID | cut -c 123)
        gVerticalRez_st=$(echo $gEDID | cut -c 119-120)
        gVerticalRez=$((0x$gVerticalRez_pr$gVerticalRez_st))
      else
        #
        # No, we cannot assess EDID from ioreg. But now the resolution of current display has been forced to the highest resolution as vendor designed.
        #
        gSystemRez=$(system_profiler SPDisplaysDataType | grep -i "Resolution" | sed -e 's/.*://')
        gSystemHorizontalRez=$(echo $gSystemRez | sed -e 's/x.*//')
        gSystemVerticalRez=$(echo $gSystemRez | sed -e 's/.*x//')
    fi

    #
    # Patch IOKit?
    #
    if [[ $gHorizontalRez -gt 1920 || $gSystemHorizontalRez -gt 1920 ]];
      then
        #
        # Yes, We indeed require a patch to unlock the limitation of flash rate of IOKit to power up the QHD+/4K display.
        #
        # Note: the argument of gPatchIOKit is set to 0 as default if the examination of resolution fail, this argument can ensure all model being powered up.
        #
        gPatchIOKit=0
      else
        #
        # No, patch IOKit is not required, we won't touch IOKit(for a more intergration/clean system since less is more).
        #
        gPatchIOKit=1
    fi
}

#
#--------------------------------------------------------------------------------
#

function _check_and_fix_config()
{
    #
    # Check if the ig-platform-id is correct(i.e. ig-platform-id = 0x0a2e0008).
    #
    target_ig_platform_id="0x0a2e0008"
    gClover_ig_platform_id=$(awk '/<key>ig-platform-id<\/key>.*/,/<\/string>/' ${config_plist} | egrep -o '(<string>.*</string>)' | sed -e 's/<\/*string>//g')

    if [[ $gClover_ig_platform_id != $target_ig_platform_id ]];
      then
        #
        # Yes, we have to touch/modify the config.plist.
        #
        sed -ig "s/$gClover_ig_platform_id/$target_ig_platform_id/g" ${config_plist}
    fi

    #
    # Repair the lid wake problem for 0x0a2e0008 by syscl/lighting/Yating Zhou.
    #
    # Check if the binary patch for AppleIntelFramebufferAzul is in the right place.
    #
    gClover_kexts_to_patch_data=$(awk '/<key>KextsToPatch<\/key>.*/,/<\/array>/' ${config_plist})
    find_lid_byte="40000000 1e000000 05050901"
    replace_lid_byte="40000000 0f000000 05050901"

    #
    # Convert to base64.
    #
    find_lid_byte_ENCODE=$(echo $find_lid_byte | xxd -r -p | base64)
    replace_lid_byte_ENCODE=$(echo $replace_lid_byte | xxd -r -p | base64)

    if [[ $gClover_kexts_to_patch_data != *"$find_lid_byte_ENCODE"* || $gClover_kexts_to_patch_data != *"$replace_lid_byte_ENCODE"* ]];
      then
        #
        # No patch existed in config.plist, add patch for it:
        #
        _add_kexts_to_patch_infoplist "Enable lid wake after sleep for 0a2e0008 (c) syscl/lighting/Yating Zhou" "$find_lid_byte_ENCODE" "$replace_lid_byte_ENCODE" "AppleIntelFramebufferAzul"
    fi

    #
    # Check if "Enable 128MB BIOS, 48MB Framebuffer, 48MB Cursor for Azul framebuffer 0xa2e0008" is in config.plist.
    #
    find_Azul_data="08002e0a 01030303 00000004 00002002 00005001"
    replace_Azul_data="08002e0a 01030303 00000008 00000003 00000003"

    #
    # Convert to base64.
    #
    find_Azul_data_ENCODE=$(echo $find_Azul_data | xxd -r -p | base64)
    replace_Azul_data_ENCODE=$(echo $replace_Azul_data | xxd -r -p | base64)

    if [[ $gClover_kexts_to_patch_data != *"$find_Azul_data_ENCODE"* || $gClover_kexts_to_patch_data != *"$replace_Azul_data_ENCODE"* ]];
      then
        #
        # No patch existed in config.plist, add patch for it:
        #
        _add_kexts_to_patch_infoplist "Enable 128MB BIOS, 48MB Framebuffer, 48MB Cursor for Azul framebuffer 0xa2e0008" "$find_Azul_data_ENCODE" "$replace_Azul_data_ENCODE" "AppleIntelFramebufferAzul"
    fi

    #
    # Check if "Enable HD4600 HDMI Audio" is located in config.plist.
    #
    find_hdmi_bytes="3D0C0A00 00"
    replace_hdmi_bytes="3D0C0C00 00"

    #
    # Convert to base64.
    #
    find_hdmi_bytes_ENCODE=$(echo $find_hdmi_bytes | xxd -r -p | base64)
    replace_hdmi_bytes_ENCODE=$(echo $replace_hdmi_bytes | xxd -r -p | base64)

    if [[ $gClover_kexts_to_patch_data != *"$find_hdmi_bytes_ENCODE"* || $gClover_kexts_to_patch_data != *"$replace_hdmi_bytes_ENCODE"* ]];
      then
        #
        # No patch existed in config.plist, add patch for it:
        #
        _add_kexts_to_patch_infoplist "Enable HD4600 HDMI Audio" "$find_hdmi_bytes_ENCODE" "$replace_hdmi_bytes_ENCODE" "AppleHDAController"
    fi
}

#
#--------------------------------------------------------------------------------
#

function _add_kexts_to_patch_infoplist()
{
    local comment=$1
    local find_binary_ENCODE=$2
    local replace_binary_ENCODE=$3
    local binary_name=$4
    index=$(awk '/<key>KextsToPatch<\/key>.*/,/<\/array>/' ${config_plist} | grep -i "Name" | wc -l)

    #
    # Inject comment.
    #
    /usr/libexec/plistbuddy -c "Add ':KernelAndKextPatches:KextsToPatch:$index' dict" ${config_plist}
    /usr/libexec/plistbuddy -c "Add ':KernelAndKextPatches:KextsToPatch:$index:Comment' string" ${config_plist}
    /usr/libexec/plistbuddy -c "Set ':KernelAndKextPatches:KextsToPatch:$index:Comment' $comment" ${config_plist}

    #
    # Disabled = Nope.
    #
    /usr/libexec/plistbuddy -c "Add ':KernelAndKextPatches:KextsToPatch:$index:Disabled' bool" ${config_plist}
    /usr/libexec/plistbuddy -c "Set ':KernelAndKextPatches:KextsToPatch:$index:Disabled' false" ${config_plist}

    #
    # Inject find binary.
    #
    /usr/libexec/plistbuddy -c "Add ':KernelAndKextPatches:KextsToPatch:$index:Find' data" ${config_plist}
    /usr/libexec/plistbuddy -c "Set ':KernelAndKextPatches:KextsToPatch:$index:Find' syscl" ${config_plist}
    sed -ig "s/c3lzY2w=/$find_binary_ENCODE/g" ${config_plist}

    #
    # Inject name.
    #
    /usr/libexec/plistbuddy -c "Add ':KernelAndKextPatches:KextsToPatch:$index:Name' string" ${config_plist}
    /usr/libexec/plistbuddy -c "Set ':KernelAndKextPatches:KextsToPatch:$index:Name' $binary_name" ${config_plist}

    #
    # Inject replace binary.
    #
    /usr/libexec/plistbuddy -c "Add ':KernelAndKextPatches:KextsToPatch:$index:Replace' data" ${config_plist}
    /usr/libexec/plistbuddy -c "Set ':KernelAndKextPatches:KextsToPatch:$index:Replace' syscl" ${config_plist}
    sed -ig "s/c3lzY2w=/$replace_binary_ENCODE/g" ${config_plist}
}

#
#--------------------------------------------------------------------------------
#

function _find_acpi()
{
    #
    # Search specification tables by syscl/Yating Zhou.
    #
    number=$(ls "${REPO}"/DSDT/raw/SSDT*.dsl | wc -l)

    #
    # Search DptfTa.
    #
    for ((index = 1; index <= ${number}; index++))
    do
      grep -i "DptfTa" "${REPO}"/DSDT/raw/SSDT-${index}.dsl &> /dev/null && RETURN_VAL=0 || RETURN_VAL=1

      if [ "${RETURN_VAL}" == 0 ];
        then
          DptfTa=SSDT-${index}
      fi
    done

    #
    # Search SaSsdt.
    #
    for ((index = 1; index <= ${number}; index++))
    do
      grep -i "SaSsdt" "${REPO}"/DSDT/raw/SSDT-${index}.dsl &> /dev/null && RETURN_VAL=0 || RETURN_VAL=1

      if [ "${RETURN_VAL}" == 0 ];
        then
          SaSsdt=SSDT-${index}
      fi
    done

    #
    # Search SgRef.
    #
    for ((index = 1; index <= ${number}; index++))
    do
      grep -i "SgRef" "${REPO}"/DSDT/raw/SSDT-${index}.dsl &> /dev/null && RETURN_VAL=0 || RETURN_VAL=1

      if [ "${RETURN_VAL}" == 0 ];
        then
          SgRef=SSDT-${index}
      fi
    done

    #
    # Search OptRef.
    #
    for ((index = 1; index <= ${number}; index++))
    do
      grep -i "OptRef" "${REPO}"/DSDT/raw/SSDT-${index}.dsl &> /dev/null && RETURN_VAL=0 || RETURN_VAL=1

      if [ "${RETURN_VAL}" == 0 ];
        then
          OptRef=SSDT-${index}
      fi
    done
}

#
#--------------------------------------------------------------------------------
#

function _update_clover_kext()
{
    #
    # Gain OS generation.
    #
    gProductVersion="$(sw_vers -productVersion)"
    OS_Version=$(echo ${gProductVersion:0:5})
    KEXT_DIR=/Volumes/EFI/EFI/CLOVER/kexts/${OS_Version}

    #
    # Updating kexts. NOTE: This progress will remove any previous kexts.
    #
    _PRINT_MSG "--->: ${BLUE}Updating kexts...${OFF}"
    tidy_execute "rm -rf ${KEXT_DIR}" "Remove pervious kexts in ${KEXT_DIR}"
    tidy_execute "cp -R ./CLOVER/kexts/${OS_Version} /Volumes/EFI/EFI/CLOVER/kexts/" "Update kexts from ./CLOVER/kexts/${OS_Version}"
    tidy_execute "cp -R ./Kexts/*.kext ${KEXT_DIR}/" "Update kexts from ./Kexts"
}

#
#--------------------------------------------------------------------------------
#

function main()
{
    #
    # Sync all files from https://github.com/syscl/M3800
    #
    # Check if github is available
    #
    _update

    #
    # Generate dir.
    #
    tidy_execute "create_dir "${REPO}/DSDT"" "Create ./DSDT"
    tidy_execute "create_dir "${prepare}"" "Create ./DSDT/prepare"
    tidy_execute "create_dir "${precompile}"" "Create ./DSDT/precompile"
    tidy_execute "create_dir "${compile}"" "Create ./DSDT/compile"

    #
    # Mount esp.
    #
    diskutil list
    read -p "Enter EFI's IDENTIFIER, e.g. disk0s1: " targetEFI
    locate_esp ${targetEFI}
    tidy_execute "diskutil mount ${targetEFI}" "Mount ${targetEFI}"

    #
    # Ensure / Force Graphics card to power.
    #
    _initIntel
    _getEDID

    #
    # Copy origin aml to raw.
    #
    if [ -f /Volumes/EFI/EFI/CLOVER/ACPI/origin/DSDT.aml ];
      then
        tidy_execute "cp /Volumes/EFI/EFI/CLOVER/ACPI/origin/DSDT.aml /Volumes/EFI/EFI/CLOVER/ACPI/origin/SSDT-*.aml "${decompile}"" "Copy untouch ACPI tables"
      else
        _PRINT_MSG "NOTE: Warning!! DSDT and SSDTs doesn't exist! Press Fn+F4 under Clover to dump ACPI tables"
        # ERROR.
        #
        # Note: The exit value can be anything between 0 and 255 and thus -1 is actually 255
        #       but we use -1 here to make it clear (obviously) that something went wrong.
        #
        exit -1
    fi

    #
    # Decompile dsdt.
    #
    cd "${REPO}"
    _PRINT_MSG "--->: ${BLUE}Disassembling tables...${OFF}"
    tidy_execute ""${REPO}"/tools/iasl -w1 -da -dl "${REPO}"/DSDT/raw/DSDT.aml "${REPO}"/DSDT/raw/SSDT-*.aml" "Disassemble tables"

    #
    # Search specification tables by syscl/Yating Zhou.
    #
    tidy_execute "_find_acpi" "Search specification tables by syscl/Yating Zhou"

    #
    # DSDT Patches.
    #
    _PRINT_MSG "--->: ${BLUE}Patching DSDT.dsl${OFF}"
    tidy_execute "patch_acpi DSDT syntax "fix_PARSEOP_ZERO"" "Fix PARSEOP_ZERO"
    tidy_execute "patch_acpi DSDT syntax "fix_ADBG"" "Fix ADBG Error"
    tidy_execute "patch_acpi DSDT graphics "graphics_Rename-GFX0"" "Rename GFX0 to IGPU"
    tidy_execute "patch_acpi DSDT usb "usb_7-series"" "7-series/8-series USB"
    tidy_execute "patch_acpi DSDT usb "usb_prw_0x0d_xhc"" "Fix USB _PRW"
    tidy_execute "patch_acpi DSDT battery "battery_Acer-Aspire-E1-571"" "Acer Aspire E1-571"
    tidy_execute "patch_acpi DSDT system "system_IRQ"" "IRQ Fix"
    tidy_execute "patch_acpi DSDT system "system_SMBUS"" "SMBus Fix"
    tidy_execute "patch_acpi DSDT system "system_ADP1"" "AC Adapter Fix"
    tidy_execute "patch_acpi DSDT system "system_MCHC"" "Add MCHC"
    tidy_execute "patch_acpi DSDT system "system_WAK2"" "Fix _WAK Arg0 v2"
    tidy_execute "patch_acpi DSDT system "system_IMEI"" "Add IMEI"
    tidy_execute "patch_acpi DSDT system "system_Mutex"" "Fix Non-zero Mutex"
    tidy_execute "patch_acpi DSDT syscl "system_OSYS"" "OS Check Fix"
    tidy_execute "patch_acpi DSDT syscl "audio_HDEF-layout1"" "Add audio Layout 1"
    tidy_execute "patch_acpi DSDT syscl "audio_B0D3_HDAU"" "Rename B0D3 to HDAU"
    tidy_execute "patch_acpi DSDT syscl "remove_glan"" "Remove GLAN device"

    #
    # DptfTa Patches.
    #
    _PRINT_MSG "--->: ${BLUE}Patching ${DptfTa}.dsl${OFF}"
    tidy_execute "patch_acpi ${DptfTa} syscl "_BST-package-size"" "_BST package size"
    tidy_execute "patch_acpi ${DptfTa} graphics "graphics_Rename-GFX0"" "Rename GFX0 to IGPU"

    #
    # SaSsdt Patches.
    #
    _PRINT_MSG "--->: ${BLUE}Patching ${SaSsdt}.dsl${OFF}"
    tidy_execute "patch_acpi ${SaSsdt} graphics "graphics_Rename-GFX0"" "Rename GFX0 to IGPU"
    tidy_execute "patch_acpi ${SaSsdt} syscl "syscl_Iris_Pro"" "Rename HD4600 to Iris Pro"
    tidy_execute "patch_acpi ${SaSsdt} graphics "graphics_PNLF_haswell"" "Brightness fix (Haswell)"
    tidy_execute "patch_acpi ${SaSsdt} syscl "audio_B0D3_HDAU"" "Rename B0D3 to HDAU"
    tidy_execute "patch_acpi ${SaSsdt} syscl "audio_Intel_HD4600"" "Insert HDAU device"

    #
    # SgRef Patches.
    #
    _PRINT_MSG "--->: ${BLUE}Patching ${SgRef}.dsl${OFF}"
    tidy_execute "patch_acpi ${SgRef} graphics "graphics_Rename-GFX0"" "Rename GFX0 to IGPU"

    #
    # OptRef Patches.
    #
    _PRINT_MSG "--->: ${BLUE}Patching ${OptRef}.dsl${OFF}"
    tidy_execute "patch_acpi ${OptRef} syscl "WMMX-invalid-operands"" "Remove invalid operands"
    tidy_execute "patch_acpi ${OptRef} graphics "graphics_Rename-GFX0"" "Rename GFX0 to IGPU"
    tidy_execute "patch_acpi ${OptRef} syscl "graphics_Disable_Nvidia"" "Disable Nvidia card (Non-operational in OS X)"

    #
    # Copy all tables to precompile.
    #
    _PRINT_MSG "--->: ${BLUE}Copying tables to precompile...${OFF}"
    tidy_execute "cp "${raw}/"*.dsl "${precompile}"" "Copy tables to precompile"

    #
    # Copy raw tables to compile.
    #
    _PRINT_MSG "--->: ${BLUE}Copying untouched tables to ./DSDT/compile...${OFF}"
    tidy_execute "cp "${raw}"/SSDT-*.aml "$compile"" "Copy untouched tables to ./DSDT/compile"

    #
    # Compile tables.
    #
    _PRINT_MSG "--->: ${BLUE}Compiling tables...${OFF}"
    tidy_execute "compile_table "DSDT"" "Compiling DSDT"
    tidy_execute "compile_table "${DptfTa}"" "Compile DptfTa"
    tidy_execute "compile_table "${SaSsdt}"" "Compile SaSsdt"
    tidy_execute "compile_table "${SgRef}"" "Compile SgRef"
    tidy_execute "compile_table "${OptRef}"" "Compile OptRef"

    #
    # Copy SSDT-rmne.aml.
    #
    _PRINT_MSG "--->: ${BLUE}Copying SSDT-rmne.aml to ./DSDT/compile...${OFF}"
    tidy_execute "cp "${prepare}"/SSDT-rmne.aml "${compile}"" "Copy SSDT-rmne.aml to ./DSDT/compile"

    #
    # Detect which SSDT for processor to be installed.
    #
    if [[ `sysctl machdep.cpu.brand_string` == *"i7-4702HQ"* ]];
      then
        tidy_execute "cp "${prepare}"/CpuPm-4702HQ.aml "${compile}"/SSDT-pr.aml" "Generate C-States and P-State for Intel ${BLUE}i7-4702HQ${OFF}"
    fi

    if [[ `sysctl machdep.cpu.brand_string` == *"i7-4712HQ"* ]]
      then
        tidy_execute "cp "${prepare}"/CpuPm-4712HQ.aml "${compile}"/SSDT-pr.aml" "Generate C-States and P-State for Intel ${BLUE}i7-4712HQ${OFF}"
    fi

    #
    # Clean up dynamic SSDTs.
    #
    tidy_execute "rm "${compile}"SSDT-*x.aml" "Clean dynamic SSDTs"

    #
    # Copy AML to destination place.
    #
    tidy_execute "create_dir "/Volumes/EFI/EFI/CLOVER/ACPI/patched"" "Create /Volumes/EFI/EFI/CLOVER/ACPI/patched"
    tidy_execute "cp "${compile}"*.aml /Volumes/EFI/EFI/CLOVER/ACPI/patched" "Copy tables to /Volumes/EFI/EFI/CLOVER/ACPI/patched"

    #
    # Refresh kext in Clover.
    #
    _update_clover_kext

    #
    # Install audio.
    #
    _PRINT_MSG "--->: ${BLUE}Installing audio...${OFF}"
    tidy_execute "install_audio" "Install audio"

    #
    # Rebuild kernel extensions cache.
    #
    _PRINT_MSG "--->: ${BLUE}Rebuilding kernel extensions cache...${OFF}"
    tidy_execute "rebuild_kernel_cache" "Rebuild kernel extensions cache"

    #
    # Patch IOKit.
    #
    _PRINT_MSG "NOTE: You need to change ${BOLD}System Agent (SA) Configuration—>Graphics Configuration->DVMT Pre-Allocated->${RED}『128MB』${OFF}"

    if [[ $gPatchIOKit ]];
      then
        #
        # Patch IOKit.
        #
        _PRINT_MSG "--->: ${BLUE}Patching IOKit for maximum pixel clock...${OFF}"
        sudo perl -i.bak -pe 's|\xB8\x01\x00\x00\x00\xF6\xC1\x01\x0F\x85|\x33\xC0\x90\x90\x90\x90\x90\x90\x90\xE9|sg' /System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit
        tidy_execute "sudo codesign -f -s - /System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit" "Sign /System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit"
    fi

    #
    # Lead to lid wake on 0x0a2e0008 by syscl/lighting/Yating Zhou
    #
    _PRINT_MSG "--->: ${BLUE}Leading to lid wake on 0x0a2e0008 (c) syscl/lighting/Yating Zhou...${OFF}"
    tidy_execute "_check_and_fix_config" "Lead to lid wake on 0x0a2e0008 (c) syscl/lighting/Yating Zhou"

    #
    # Clean up.
    #
    tidy_execute "rm ${EFI_INFO}" "Clean up after installation"

    _PRINT_MSG "NOTE: Congratulations! All operation has been completed! Reboot now. Then enjoy your OS X! --syscl/lighting/Yating Zhou @PCBeta"
}

#==================================== START =====================================

main

#================================================================================

exit ${RETURN_VAL}