#!/bin/sh

#
# syscl/Yating Zhou/lighting from bbs.PCBeta.com
# Merge for Dell Precision M3800 and XPS15 (9530).
#

#================================= GLOBAL VARS ==================================

#
# The script expects '0.5' but non-US localizations use '0,5' so we export
# LC_NUMERIC here (for the duration of the deploy.sh) to prevent errors.
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
config_plist="/Volumes/EFI/EFI/CLOVER/config.plist"
EFI_INFO="${REPO}/DSDT/EFIINFO"
gInstall_Repo="/usr/local/sbin/"
gFrom="${REPO}/tools"
gUSBSleepConfig="/tmp/com.syscl.externalfix.sleepwatcher.plist"
gUSBSleepScript="/tmp/sysclusbfix.sleep"
to_Plist="/Library/LaunchDaemons/com.syscl.externalfix.sleepwatcher.plist"
to_shell="/etc/sysclusbfix.sleep"
drivers64UEFI="${REPO}/CLOVER/drivers64UEFI"
t_drivers64UEFI="/Volumes/EFI/EFI/CLOVER/drivers64UEFI"
clover_tools="${REPO}/CLOVER/tools"
t_clover_tools="/Volumes/EFI/EFI/CLOVER/tools"

#
# Define variables.
#
# Gvariables stands for getting datas from OS X.
#
gArgv=""
gDebug=1
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
gMINOR_VER=""
find_handoff_bytes=""
replace_handoff_bytes=""
find_handoff_bytes_ENCODE=""
replace_handoff_bytes_ENCODE=""
gTriggerLE=1
gMINOR_VER=$([[ "$(sw_vers -productVersion)" =~ [0-9]+\.([0-9]+) ]] && echo ${BASH_REMATCH[1]})

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

    case "$message" in
      OK*    ) local message=$(echo $message | sed -e 's/.*OK://')
               echo "[  ${GREEN}OK${OFF}  ] ${message}."
               ;;

      FAILED*) local message=$(echo $message | sed -e 's/.*://')
               echo "[${RED}FAILED${OFF}] ${message}."
               ;;

      ---*   ) local message=$(echo $message | sed -e 's/.*--->://')
               echo "[ ${GREEN}--->${OFF} ] ${message}"
               ;;

      NOTE*  ) local message=$(echo $message | sed -e 's/.*NOTE://')
               echo "[ ${RED}Note${OFF} ] ${message}."
               ;;
    esac
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

function _tidy_exec()
{
    if [ $gDebug -eq 0 ];
      then
        #
        # Using debug mode to output all the details.
        #
        _PRINT_MSG "DEBUG: $2"
        $1
      else
        #
        # Make the output clear.
        #
        $1 >/tmp/report 2>&1 && RETURN_VAL=0 || RETURN_VAL=1

        if [ "${RETURN_VAL}" == 0 ];
          then
            _PRINT_MSG "OK: $2"
          else
            _PRINT_MSG "FAILED: $2"
            cat /tmp/report
        fi

        rm /tmp/report &> /dev/null
    fi
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
    if [ $gTriggerLE -eq 0 ];
      then
        #
        # Yes, we do touch /L*/E*.
        #
        sudo touch /Library/Extensions
    fi

    #
    # /S*/L*/E* must be touched to prevent some potential issues.
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
    # Remove previous AppleHDA_ALC668.kext & CodecCommander.kext.
    #
    _del /Library/Extensions/Apple_ALC668.kext
    _del /Library/Extensions/CodecCommander.kext

    #
    # Added detection to prevent failure of remove.
    #
    _del /System/Library/Extensions/Apple_ALC668.kext
    _del /System/Library/Extensions/CodecCommander.kext
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
        # Note: the argument of gPatchIOKit is set to 0 as default if the examination of resolution fail, this argument can ensure all models being powered up.
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

function _upd_EFI()
{
    #
    # Update EFI drivers/Clover.
    #
    local gMD_st=$(md5 -q "$1")
    #
    # Target EFI/Clover files.
    #
    local gMD_nd=$(md5 -q "$2")

    if [[ $gMD_st != $gMD_nd ]];
      then
        #
        # Yes, ne, update Clover.
        #
        _tidy_exec "cp "$1" "$2"" "Update $2"
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
        _add_kexts_to_patch_infoplist "Enable lid wake after sleep for 0x0a2e0008 (c) syscl/lighting/Yating Zhou" "$find_lid_byte_ENCODE" "$replace_lid_byte_ENCODE" "AppleIntelFramebufferAzul"
    fi

    #
    # Check if "Enable 160MB BIOS, 48MB Framebuffer, 48MB Cursor for Azul framebuffer 0x0a2e0008" is in config.plist.
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
        _add_kexts_to_patch_infoplist "Enable 160MB BIOS, 48MB Framebuffer, 48MB Cursor for Azul framebuffer 0x0a2e0008" "$find_Azul_data_ENCODE" "$replace_Azul_data_ENCODE" "AppleIntelFramebufferAzul"
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

    #
    # Check if "BT4LE-Handoff-Hotspot" is in place of kextstopatch.
    #
    # The first step is to check the minor version of OS X(e.g. 10.10 vs. 10.11).
    #
    if [[ $gMINOR_VER -ge 11 ]];
      then
        #
        # OS X is 10.11+.
        #
        find_handoff_bytes="4885ff74 47488b07"
        replace_handoff_bytes="41be0f00 0000eb44"
      else
        #
        # OS X is 10.10-.
        #
        find_handoff_bytes="4885c074 5c0fb748"
        replace_handoff_bytes="41be0f00 0000eb59"
    fi

    #
    # Convert to base64.
    #
    find_handoff_bytes_ENCODE=$(echo $find_handoff_bytes | xxd -r -p | base64)
    replace_handoff_bytes_ENCODE=$(echo $replace_handoff_bytes | xxd -r -p | base64)

    if [[ $gClover_kexts_to_patch_data != *"$find_handoff_bytes_ENCODE"* || $gClover_kexts_to_patch_data != *"$replace_handoff_bytes_ENCODE"* ]];
      then
        #
        # No patch existed in config.plist, add patch for it:
        #
        _add_kexts_to_patch_infoplist "Enable BT4LE-Handoff-Hotspot" "$find_handoff_bytes_ENCODE" "$replace_handoff_bytes_ENCODE" "IOBluetoothFamily"
    fi

    #
    # Gain boot argv.
    #
    local gBootArgv=$(awk '/<key>NoEarlyProgress<\/key>.*/,/<*\/>/' ${config_plist})

    if [[ $gBootArgv != *"NoEarlyProgress"* ]];
      then
        #
        # Add argv to prevent/remove "Welcome to Clover... Scan Entries" at early startup.
        #
        /usr/libexec/plistbuddy -c "Add ':Boot:NoEarlyProgress' bool" "${config_plist}"
        /usr/libexec/plistbuddy -c "Set ':Boot:NoEarlyProgress' true" "${config_plist}"
      else
        if [[ $gBootArgv == *"false"* ]];
          then
            /usr/libexec/plistbuddy -c "Set ':Boot:NoEarlyProgress' true" "${config_plist}"
        fi
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
    sed -ig "s|c3lzY2w=|$find_binary_ENCODE|g" ${config_plist}

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
    sed -ig "s|c3lzY2w=|$replace_binary_ENCODE|g" ${config_plist}
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

function _update_clover()
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
    _tidy_exec "rm -rf ${KEXT_DIR}" "Remove pervious kexts in ${KEXT_DIR}"
    _tidy_exec "cp -R ./CLOVER/kexts/${OS_Version} /Volumes/EFI/EFI/CLOVER/kexts/" "Update kexts from ./CLOVER/kexts/${OS_Version}"
    _tidy_exec "cp -R ./Kexts/*.kext ${KEXT_DIR}/" "Update kexts from ./Kexts"

    #
    # Decide which BT kext to use.
    #
    if [[ `ioreg` == *"BCM20702A3"* ]];
      then
        #
        # BCM20702A3 found.
        #
        _tidy_exec "rm -R ${KEXT_DIR}/BrcmFirmwareRepo.kext" "BCM20702A3 found"
      else
        #
        # BCM2045A0 found. We remove BrcmFirmwareData.kext to prevent this driver crashes the whole system during boot.
        #
        _tidy_exec "rm -R ${KEXT_DIR}/BrcmFirmwareData.kext" "BCM2045A0 found"
    fi

    #
    # Decide which kext to be installed for BT.
    #
    if [[ $gMINOR_VER -ge 11 ]];
      then
        #
        # OS X is 10.11+.
        #
        _tidy_exec "rm -R ${KEXT_DIR}/BrcmPatchRAM.kext" "Remove redundant BT driver: BrcmPatchRAM.kext"
      else
        #
        # OS X is 10.10-.
        #
        _tidy_exec "rm -R ${KEXT_DIR}/BrcmPatchRAM2.kext" "Remove redundant BT driver: BrcmPatchRAM2.kext"
    fi

    #
    # gEFI.
    #
    drvEFI=("FSInject-64.efi" "HFSPlus.efi" "OsxAptioFix2Drv-64.efi" "OsxFatBinaryDrv-64.efi" "DataHubDxe-64.efi")
    efiTOOL=("Shell.inf" "Shell32.efi" "Shell64.efi" "Shell64U.efi" "bdmesg-32.efi" "bdmesg.efi")

    #
    # Check if necessary to update Clover.
    #
    for filename in "${drvEFI[@]}"
    do
        _upd_EFI "${drivers64UEFI}/${filename}" "${t_drivers64UEFI}/${filename}"
    done

    for filename in "${efiTOOL[@]}"
    do
      _upd_EFI "${clover_tools}/${filename}" "${t_clover_tools}/${filename}"
    done

    #
    # Update CLOVERX64.efi
    #
    _upd_EFI "${REPO}/CLOVER/CLOVERX64.efi" "/Volumes/EFI/EFI/CLOVER/CLOVERX64.efi"
}

#
#--------------------------------------------------------------------------------
#

function _update_thm()
{
    if [ -d /Volumes/EFI/EFI/CLOVER/themes/bootcamp ];
      then
        if [[ `cat /Volumes/EFI/EFI/CLOVER/themes/bootcamp/theme.plist` != *"syscl"* ]];
          then
            #
            # Yes we need to update themes.
            #
            rm -R /Volumes/EFI/EFI/CLOVER/themes/bootcamp
            cp -R ${REPO}/CLOVER/themes/BootCamp /Volumes/EFI/EFI/CLOVER/themes
        fi
    fi
}

#
#--------------------------------------------------------------------------------
#

function _printUSBSleepConfig()
{
    _del ${gUSBSleepConfig}

    echo '<?xml version="1.0" encoding="UTF-8"?>'                                                                                                           > "$gUSBSleepConfig"
    echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'                                          >> "$gUSBSleepConfig"
    echo '<plist version="1.0">'                                                                                                                           >> "$gUSBSleepConfig"
    echo '<dict>'                                                                                                                                          >> "$gUSBSleepConfig"
    echo '	<key>KeepAlive</key>'                                                                                                                          >> "$gUSBSleepConfig"
    echo '	<true/>'                                                                                                                                       >> "$gUSBSleepConfig"
    echo '	<key>Label</key>'                                                                                                                              >> "$gUSBSleepConfig"
    echo '	<string>com.syscl.externalfix.sleepwatcher</string>'                                                                                           >> "$gUSBSleepConfig"
    echo '	<key>ProgramArguments</key>'                                                                                                                   >> "$gUSBSleepConfig"
    echo '	<array>'                                                                                                                                       >> "$gUSBSleepConfig"
    echo '		<string>/usr/local/sbin/sleepwatcher</string>'                                                                                             >> "$gUSBSleepConfig"
    echo '		<string>-V</string>'                                                                                                                       >> "$gUSBSleepConfig"
    echo '		<string>-s /etc/sysclusbfix.sleep</string>'                                                                                                >> "$gUSBSleepConfig"
    echo '	</array>'                                                                                                                                      >> "$gUSBSleepConfig"
    echo '	<key>RunAtLoad</key>'                                                                                                                          >> "$gUSBSleepConfig"
    echo '	<true/>'                                                                                                                                       >> "$gUSBSleepConfig"
    echo '</dict>'                                                                                                                                         >> "$gUSBSleepConfig"
    echo '</plist>'                                                                                                                                        >> "$gUSBSleepConfig"
}

#
#--------------------------------------------------------------------------------
#

function _createUSB_Sleep_Script()
{
    #
    # Remove previous script.
    #
    _del ${gUSBSleepScript}

    echo '#!/bin/sh'                                                                                                                                         > "$gUSBSleepScript"
    echo '#'                                                                                                                                                >> "$gUSBSleepScript"
    echo '# This script aims to unmount all external devices automatically before sleep.'                                                                   >> "$gUSBSleepScript"
    echo '#'                                                                                                                                                >> "$gUSBSleepScript"
    echo '# Without this procedure, various computers with OS X/Mac OS X(even on a real Mac) suffer from "Disk not ejected properly"'                       >> "$gUSBSleepScript"
    echo '# issue when there're external devices plugged-in. That's the reason why I created this script to fix this issue. (syscl/lighting/Yating Zhou)'   >> "$gUSBSleepScript"
    echo '#'                                                                                                                                                >> "$gUSBSleepScript"
    echo '# All credit to Bernhard Baehr (bernhard.baehr@gmx.de), without his great sleepwatcher dameon, this fix will not be created.'                     >> "$gUSBSleepScript"
    echo '#'                                                                                                                                                >> "$gUSBSleepScript"
    echo ''                                                                                                                                                 >> "$gUSBSleepScript"
    echo '#'                                                                                                                                                >> "$gUSBSleepScript"
    echo '# Added unmount Disk for "OS X" (c) syscl/lighting/Yating Zhou.'                                                                                  >> "$gUSBSleepScript"
    echo '#'                                                                                                                                                >> "$gUSBSleepScript"
    echo ''                                                                                                                                                 >> "$gUSBSleepScript"
    echo 'diskutil list | grep -i "External" | sed -e "s| (external, physical):||" | xargs -I {} diskutil eject {}'                                         >> "$gUSBSleepScript"
}

#
#--------------------------------------------------------------------------------
#

function _del()
{
    local target_file=$1

    if [ -d ${target_file} ];
      then
        _tidy_exec "sudo rm -R ${target_file}" "Remove ${target_file}"
      else
        if [ -f ${target_file} ];
          then
            _tidy_exec "sudo rm ${target_file}" "Remove ${target_file}"
        fi
    fi
}

#
#--------------------------------------------------------------------------------
#

function _touch()
{
    local target_file=$1

    if [ ! -d ${target_file} ];
      then
        _tidy_exec "sudo mkdir ${target_file}" "Create ${target_file}"
    fi
}

#
#--------------------------------------------------------------------------------
#

function _fix_usb_ejected_improperly()
{
    #
    # This function fix the issue that usb ejected improperly upon sleep (c) syscl/lighting/Yating Zhou.
    #
    # Generate configuration file of sleepwatcher launch demon.
    #
    _PRINT_MSG "--->: Generating configuration file of sleepwatcher launch daemon..."
    _tidy_exec "_printUSBSleepConfig" "Generate configuration file of sleepwatcher launch daemon"

    #
    # Generate script to unmount external devices before sleep (c) syscl/lighting/Yating Zhou.
    #
    _PRINT_MSG "--->: Generating script to unmount external devices before sleep..."
    _tidy_exec "_createUSB_Sleep_Script" "Generating script to unmount external devices before sleep"

    #
    # Install sleepwatcher daemon.
    #
    _del /Library/LaunchDaemons/de.bernhard-baehr.sleepwatcher.plist
    _PRINT_MSG "--->: Installing external devices sleep patch..."
    _touch "${gInstall_Repo}"
    _tidy_exec "sudo cp "${gFrom}/sleepwatcher" "${gInstall_Repo}"" "Install sleepwatcher daemon"
    _tidy_exec "sudo cp "${gUSBSleepConfig}" "${to_Plist}"" "Install configuration of sleepwatcher daemon"
    _tidy_exec "sudo cp "${gUSBSleepScript}" "${to_shell}"" "Install sleepwatcher script"
    _tidy_exec "sudo chmod 744 ${to_shell}" "Fix the permissions of the file(s)"
    _tidy_exec "sudo launchctl load ${to_Plist}" "Trigger startup service of syscl.usb.fix"

    #
    # Clean up.
    #
    _tidy_exec "rm $gUSBSleepConfig $gUSBSleepScript" "Clean up"
}

#
#--------------------------------------------------------------------------------
#

function _check_external_eth()
{
    #
    # Check if there's external devices/kexts get installed. If yes, sleep fix is needed.
    #
    local gExt_ETH=1

    if [ -d /System/Library/Extensions/*RTL*.kext ];
      then
        gExt_ETH=0
      else
        if [ -d /Library/Extensions/*RTL*.kext ];
          then
            gExt_ETH=0
          else
            gExt_ETH=1
        fi
    fi
}

#
#--------------------------------------------------------------------------------
#

function main()
{
    #
    # Get argument.
    #
    gArgv=$(echo "$@" | tr '[:lower:]' '[:upper:]')
    if [[ $# -eq 1 && "$gArgv" == "-D" || "$gArgv" == "-DEBUG" ]];
      then
        #
        # Yes, we do need debug mode.
        #
        _PRINT_MSG "NOTE: Use ${BLUE}DEBUG${OFF} mode"
        gDebug=0
      else
        #
        # No, we need a clean output style.
        #
        gDebug=1
    fi

    #
    # Sync all files from https://github.com/syscl/M3800
    #
    # Check if github is available
    #
    _update

    #
    # Generate dir.
    #
    _tidy_exec "create_dir "${REPO}/DSDT"" "Create ./DSDT"
    _tidy_exec "create_dir "${prepare}"" "Create ./DSDT/prepare"
    _tidy_exec "create_dir "${precompile}"" "Create ./DSDT/precompile"
    _tidy_exec "create_dir "${compile}"" "Create ./DSDT/compile"

    #
    # Mount esp.
    #
    diskutil list
    read -p "Enter EFI's IDENTIFIER, e.g. disk0s1: " targetEFI
    locate_esp ${targetEFI}
    _tidy_exec "diskutil mount ${targetEFI}" "Mount ${targetEFI}"

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
        _tidy_exec "cp /Volumes/EFI/EFI/CLOVER/ACPI/origin/DSDT.aml /Volumes/EFI/EFI/CLOVER/ACPI/origin/SSDT-*.aml "${decompile}"" "Copy untouch ACPI tables"
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
    _tidy_exec ""${REPO}"/tools/iasl -w1 -da -dl "${REPO}"/DSDT/raw/DSDT.aml "${REPO}"/DSDT/raw/SSDT-*.aml" "Disassemble tables"

    #
    # Search specification tables by syscl/Yating Zhou.
    #
    _tidy_exec "_find_acpi" "Search specification tables by syscl/Yating Zhou"

    #
    # DSDT Patches.
    #
    _PRINT_MSG "--->: ${BLUE}Patching DSDT.dsl${OFF}"
    _tidy_exec "patch_acpi DSDT syntax "fix_PARSEOP_ZERO"" "Fix PARSEOP_ZERO"
    _tidy_exec "patch_acpi DSDT syntax "fix_ADBG"" "Fix ADBG Error"
    _tidy_exec "patch_acpi DSDT graphics "graphics_Rename-GFX0"" "Rename GFX0 to IGPU"
    _tidy_exec "patch_acpi DSDT usb "usb_7-series"" "7-series/8-series USB"
    _tidy_exec "patch_acpi DSDT usb "usb_prw_0x0d_xhc"" "Fix USB _PRW"
    _tidy_exec "patch_acpi DSDT battery "battery_Acer-Aspire-E1-571"" "Acer Aspire E1-571"
    _tidy_exec "patch_acpi DSDT system "system_IRQ"" "IRQ Fix"
    _tidy_exec "patch_acpi DSDT system "system_SMBUS"" "SMBus Fix"
    _tidy_exec "patch_acpi DSDT system "system_ADP1"" "AC Adapter Fix"
    _tidy_exec "patch_acpi DSDT system "system_MCHC"" "Add MCHC"
    _tidy_exec "patch_acpi DSDT system "system_WAK2"" "Fix _WAK Arg0 v2"
    _tidy_exec "patch_acpi DSDT system "system_IMEI"" "Add IMEI"
    _tidy_exec "patch_acpi DSDT system "system_Mutex"" "Fix Non-zero Mutex"
    _tidy_exec "patch_acpi DSDT syscl "system_OSYS"" "OS Check Fix"
    _tidy_exec "patch_acpi DSDT syscl "audio_HDEF-layout1"" "Add audio Layout 1"
    _tidy_exec "patch_acpi DSDT syscl "audio_B0D3_HDAU"" "Rename B0D3 to HDAU"
    _tidy_exec "patch_acpi DSDT syscl "remove_glan"" "Remove GLAN device"

    #
    # DptfTa Patches.
    #
    _PRINT_MSG "--->: ${BLUE}Patching ${DptfTa}.dsl${OFF}"
    _tidy_exec "patch_acpi ${DptfTa} syscl "_BST-package-size"" "_BST package size"
    _tidy_exec "patch_acpi ${DptfTa} graphics "graphics_Rename-GFX0"" "Rename GFX0 to IGPU"

    #
    # SaSsdt Patches.
    #
    _PRINT_MSG "--->: ${BLUE}Patching ${SaSsdt}.dsl${OFF}"
    _tidy_exec "patch_acpi ${SaSsdt} graphics "graphics_Rename-GFX0"" "Rename GFX0 to IGPU"
    _tidy_exec "patch_acpi ${SaSsdt} syscl "syscl_Iris_Pro"" "Rename HD4600 to Iris Pro"
    _tidy_exec "patch_acpi ${SaSsdt} graphics "graphics_PNLF_haswell"" "Brightness fix (Haswell)"
    _tidy_exec "patch_acpi ${SaSsdt} syscl "audio_B0D3_HDAU"" "Rename B0D3 to HDAU"
    _tidy_exec "patch_acpi ${SaSsdt} syscl "audio_Intel_HD4600"" "Insert HDAU device"

    #
    # SgRef Patches.
    #
    _PRINT_MSG "--->: ${BLUE}Patching ${SgRef}.dsl${OFF}"
    _tidy_exec "patch_acpi ${SgRef} graphics "graphics_Rename-GFX0"" "Rename GFX0 to IGPU"

    #
    # OptRef Patches.
    #
    _PRINT_MSG "--->: ${BLUE}Patching ${OptRef}.dsl${OFF}"
    _tidy_exec "patch_acpi ${OptRef} syscl "WMMX-invalid-operands"" "Remove invalid operands"
    _tidy_exec "patch_acpi ${OptRef} graphics "graphics_Rename-GFX0"" "Rename GFX0 to IGPU"
    _tidy_exec "patch_acpi ${OptRef} syscl "graphics_Disable_Nvidia"" "Disable Nvidia card (Non-operational in OS X)"

    #
    # Copy all tables to precompile.
    #
    _PRINT_MSG "--->: ${BLUE}Copying tables to precompile...${OFF}"
    _tidy_exec "cp "${raw}/"*.dsl "${precompile}"" "Copy tables to precompile"

    #
    # Copy raw tables to compile.
    #
    _PRINT_MSG "--->: ${BLUE}Copying untouched tables to ./DSDT/compile...${OFF}"
    _tidy_exec "cp "${raw}"/SSDT-*.aml "$compile"" "Copy untouched tables to ./DSDT/compile"

    #
    # Compile tables.
    #
    _PRINT_MSG "--->: ${BLUE}Compiling tables...${OFF}"
    _tidy_exec "compile_table "DSDT"" "Compiling DSDT"
    _tidy_exec "compile_table "${DptfTa}"" "Compile DptfTa"
    _tidy_exec "compile_table "${SaSsdt}"" "Compile SaSsdt"
    _tidy_exec "compile_table "${SgRef}"" "Compile SgRef"
    _tidy_exec "compile_table "${OptRef}"" "Compile OptRef"

    #
    # Copy SSDT-rmne.aml.
    #
    _PRINT_MSG "--->: ${BLUE}Copying SSDT-rmne.aml to ./DSDT/compile...${OFF}"
    _tidy_exec "cp "${prepare}"/SSDT-rmne.aml "${compile}"" "Copy SSDT-rmne.aml to ./DSDT/compile"

    #
    # Detect which SSDT for processor to be installed.
    #
    if [[ `sysctl machdep.cpu.brand_string` == *"i7-4702HQ"* ]];
      then
        _tidy_exec "cp "${prepare}"/CpuPm-4702HQ.aml "${compile}"/SSDT-pr.aml" "Generate C-States and P-State for Intel ${BLUE}i7-4702HQ${OFF}"
    fi

    if [[ `sysctl machdep.cpu.brand_string` == *"i7-4712HQ"* ]]
      then
        _tidy_exec "cp "${prepare}"/CpuPm-4712HQ.aml "${compile}"/SSDT-pr.aml" "Generate C-States and P-State for Intel ${BLUE}i7-4712HQ${OFF}"
    fi

    #
    # Clean up dynamic SSDTs.
    #
    _tidy_exec "rm "${compile}"SSDT-*x.aml" "Clean dynamic SSDTs"

    #
    # Copy AML to destination place.
    #
    _tidy_exec "create_dir "/Volumes/EFI/EFI/CLOVER/ACPI/patched"" "Create /Volumes/EFI/EFI/CLOVER/ACPI/patched"
    _tidy_exec "cp "${compile}"*.aml /Volumes/EFI/EFI/CLOVER/ACPI/patched" "Copy tables to /Volumes/EFI/EFI/CLOVER/ACPI/patched"

    #
    # Refresh kext in Clover.
    #
    _update_clover

    #
    # Refresh BootCamp theme.
    #
    _update_thm

    #
    # Install audio.
    #
    _PRINT_MSG "--->: ${BLUE}Installing audio...${OFF}"
    _tidy_exec "install_audio" "Install audio"

    #
    # Patch IOKit.
    #
    _PRINT_MSG "NOTE: Set ${BOLD}System Agent (SA) Configuration—>Graphics Configuration->DVMT Pre-Allocated->${RED}『160MB』${OFF}"

    if [ $gPatchIOKit -eq 0 ];
      then
        #
        # Patch IOKit.
        #
        _PRINT_MSG "--->: ${BLUE}Unlocking maximum pixel clock...${OFF}"
        sudo perl -i.bak -pe 's|\xB8\x01\x00\x00\x00\xF6\xC1\x01\x0F\x85|\x33\xC0\x90\x90\x90\x90\x90\x90\x90\xE9|sg' /System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit
        _tidy_exec "sudo codesign -f -s - /System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit" "Sign IOKit"
    fi

    #
    # Lead to lid wake on 0x0a2e0008 by syscl/lighting/Yating Zhou.
    #
    _PRINT_MSG "--->: ${BLUE}Leading to lid wake on 0x0a2e0008 (c) syscl/lighting/Yating Zhou...${OFF}"
    _tidy_exec "_check_and_fix_config" "Lead to lid wake on 0x0a2e0008"

    #
    # Fix issue that external devices ejected improperly upon sleep (c) syscl/lighting/Yating Zhou.
    #
    _fix_usb_ejected_improperly

    #
    # Rebuild kernel extensions cache.
    #
    _PRINT_MSG "--->: ${BLUE}Rebuilding kernel extensions cache...${OFF}"
    _tidy_exec "rebuild_kernel_cache" "Rebuild kernel extensions cache"

    #
    # Clean up.
    #
    _tidy_exec "rm ${EFI_INFO}" "Clean up"

    _PRINT_MSG "NOTE: Congratulations! All operation has been completed"
    _PRINT_MSG "NOTE: Reboot now. Then enjoy your OS X! -${BOLD}syscl/lighting/Yating Zhou @PCBeta${OFF}"
}

#==================================== START =====================================

main "$@"

#================================================================================

exit ${RETURN_VAL}