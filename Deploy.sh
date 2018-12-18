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
# Define two status: 0 - Success, Turn on,
#                    1 - Failure, Turn off
#
kBASHReturnSuccess=0
kBASHReturnFailure=1

#
# Located repository.
#
REPO=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

#
# Path and filename setup
#
gESPMountPoint=""
decompile="${REPO}/DSDT/raw/"
precompile="${REPO}/DSDT/precompile/"
compile="${REPO}/DSDT/compile/"
tools="${REPO}/tools/"
raw="${REPO}/DSDT/raw"
prepare="${REPO}/DSDT/prepare"
config_plist=""
EFI_INFO="${REPO}/DSDT/EFIINFO"
gInstall_Repo="/usr/local/sbin/"
gFrom="${REPO}/tools"
gUSBSleepConfig="/tmp/com.syscl.externalfix.sleepwatcher.plist"
gUSBSleepScript="/tmp/sysclusbfix.sleep"
gUSBWakeScript="/tmp/sysclusbfix.wake"
gRTWlan_kext=$(ls /Library/Extensions | grep -i "Rtw" | sed 's/.kext//')
gRTWlan_Repo="/Library/Extensions"
to_Plist="/Library/LaunchDaemons/com.syscl.externalfix.sleepwatcher.plist"
to_shell_sleep="/etc/sysclusbfix.sleep"
to_shell_wake="/etc/sysclusbfix.wake"
gRT_Config="/Applications/Wireless Network Utility.app"/${gMAC_adr}rfoff.rtl
drivers64UEFI="${REPO}/CLOVER/drivers64UEFI"
t_drivers64UEFI=""
clover_tools="${REPO}/CLOVER/tools"
t_clover_tools=""

#
# Define variables.
#
# Gvariables stands for getting datas from OS X.
#
gArgv=""
gDebug=${kBASHReturnFailure}
gProductVer=""
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
gPatchIOKit=${kBASHReturnSuccess}
gClover_ig_platform_id=""
target_ig_platform_id=""
gTriggerLE=${kBASHReturnFailure}
gProductVer="$(sw_vers -productVersion)"
gOSVer=${gProductVer:0:5}
gMINOR_VER=${gProductVer:3:2}
# get increment version e.g. 10.x.y => y
gINCR_VER=$(printf ${gProductVer} | awk -F. '{print $NF}')
gBak_Time=$(date +%Y-%m-%d-h%H_%M_%S)
gBak_Dir="${REPO}/Backups/${gBak_Time}"
gStop_Bak=${kBASHReturnFailure}
gRecoveryHD=""
gRecoveryHD_DMG="/Volumes/Recovery HD/com.apple.recovery.boot/BaseSystem.dmg"
gTarget_rhd_Framework=""
gTarget_Framework_Repo=""
gBluetooth_Brand_String=""
#
# Add: Comment(string), Disabled(bool), Find(data), Name(string), Replace(data)
# Set: $comment       , false         , syscl     , $binary_name, syscl
#
gProperties_Name=(Comment Disabled Find Name Replace)
gProperties_Type=(string bool data string data)
#
# Kexts to patch
#
cLidWake=""
fLidWake=""
rLidWake=""
nLidWake=""
cAzulFrameBuffer=""
fAzulFrameBuffer=""
rAzulFrameBuffer=""
nAzulFrameBuffer=""
cHDMI=""
fHDMI=""
rHDMI=""
nHDMI=""
cHandoff=""
fHandoff=""
rHandoff=""
nHandoff=""
#
# Audio variables
#
gResources_xml_zlib=("layout1" "Platforms")
gExtensions_Repo=("/System/Library/Extensions" "/Library/Extensions")
gInjector_Repo="/tmp/AppleHDA_ALC668.kext"
gAppleHDA_Config="${gInjector_Repo}/Contents/Info.plist"
doCommands=("${REPO}/tools/iasl" "/usr/libexec/plistbuddy -c" "perl -p -e 's/(\d*\.\d*)/9\1/'")

#
# Set delimitation OS ver
#
let gDelimitation_OSVer=12

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

function _locate_rhd()
{
    #
    # Passing gRecoveryHD from ${targetEFI}
    #
    local gDisk_INF="$1"

    #
    # Example:
    #
    # disk0s3
    # ^^^^^
    diskutil list | grep -i "${gDisk_INF:0:5}" | grep "Recovery HD" |sed 's/.*MB   //'
}

#
#--------------------------------------------------------------------------------
#

function _getESPMntPoint()
{
    local gESPIndentifier="$1"
    gESPMountPoint=$(diskutil info ${gESPIndentifier} |grep -i 'Mount Point' |grep -i -o "/.*")

}

#
#--------------------------------------------------------------------------------
#

function _setESPVariable()
{
    config_plist="${gESPMountPoint}/EFI/CLOVER/config.plist"
    t_drivers64UEFI="${gESPMountPoint}/EFI/CLOVER/drivers64UEFI"
    t_clover_tools="${gESPMountPoint}/EFI/CLOVER/tools"
}

#
#--------------------------------------------------------------------------------
#

function _touch()
{
    local target_file=$1

    if [ ! -d ${target_file} ];
      then
        _tidy_exec "mkdir -p ${target_file}" "Create ${target_file}"
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
        $1 >/tmp/report 2>&1 && RETURN_VAL=${kBASHReturnSuccess} || RETURN_VAL=${kBASHReturnFailure}

        if [ "${RETURN_VAL}" == ${kBASHReturnSuccess} ];
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
#    "${REPO}"/tools/iasl -vr -w1 -ve -p "${compile}"$1.aml "${precompile}"$1.dsl
    "${REPO}"/tools/iasl -vr -p "${compile}"$1.aml "${precompile}"$1.dsl
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

function remove_patched_hda_kext()
{
    #
    # Remove previous AppleHDA_ALC668.kext & CodecCommander.kext.
    #
    for extensions in ${gExtensions_Repo[@]}
    do
        _del $extensions/AppleHDA_ALC668.kext
        _del $extensions/CodecCommander.kext
    done
}

#
#--------------------------------------------------------------------------------
#

function _check_and_fix_config()
{
    #
    # Ensure / Force Graphics card to power.
    #
    if [[ `${doCommands[1]} "Print"  "${config_plist}"` == *"Intel = false"* ]]; then
        ${doCommands[1]} "Set ':Graphics:Inject:Intel' true" "${config_plist}"
    fi
    #
    # Fix HiDPI boot graphics scale issue
    #
    if [[ $gHorizontalRez -gt 1920 || $gSystemHorizontalRez -gt 1920 ]]; then
        _PRINT_MSG "--->: ${BLUE}Setting EFILoginHiDPI & UIScale...${OFF}"
        ${doCommands[1]} "Set :BootGraphics:EFILoginHiDPI 1" "${config_plist}"
        ${doCommands[1]} "Set :BootGraphics:UIScale 2" "${config_plist}"
    else
        ${doCommands[1]} "Set :BootGraphics:EFILoginHiDPI 0" "${config_plist}"
        ${doCommands[1]} "Set :BootGraphics:UIScale 1" "${config_plist}"
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
        ${doCommands[1]} "Add ':Boot:NoEarlyProgress' bool" "${config_plist}"
        ${doCommands[1]} "Set ':Boot:NoEarlyProgress' true" "${config_plist}"
      else
        if [[ $gBootArgv == *"false"* ]];
          then
            ${doCommands[1]} "Set ':Boot:NoEarlyProgress' true" "${config_plist}"
        fi
    fi
}

#
#--------------------------------------------------------------------------------
#

function _kext2patch()
{
    local comment=$1
    local fBinaryEncode=$(_bin2base64 "$2")
    local rBinaryEncode=$(_bin2base64 "$3")
    local binary_name=$4

    local gProperties_Data=("$comment" "false" "syscl" "$binary_name" "syscl")
    index=$(awk '/<key>KextsToPatch<\/key>.*/,/<\/array>/' ${config_plist} | grep -i "Name" | wc -l)

    #
    # Inject dict with patch now.
    #
    ${doCommands[1]} "Add ':KernelAndKextPatches:KextsToPatch:$index' dict" ${config_plist}

    for ((i=0; i<${#gProperties_Name[@]}; ++i))
    do
      ${doCommands[1]} "Add ':KernelAndKextPatches:KextsToPatch:$index:${gProperties_Name[i]}' ${gProperties_Type[i]}" ${config_plist}
      ${doCommands[1]} "Set ':KernelAndKextPatches:KextsToPatch:$index:${gProperties_Name[i]}' ${gProperties_Data[i]}" ${config_plist}

      case "${gProperties_Name[i]}" in
        Find   ) sed -ig "s|c3lzY2w=|$fBinaryEncode|g" ${config_plist}
                 ;;
        Replace) sed -ig "s|c3lzY2w=|$rBinaryEncode|g" ${config_plist}
                 ;;
      esac
    done
}

#
#--------------------------------------------------------------------------------
#

function _bin2base64()
{
    echo $1 | xxd -r -p | base64
}

#
#--------------------------------------------------------------------------------
#

function _find_acpi()
{
    #
    # Search specification tables by syscl/Yating Zhou.
    #
    dslfiles=($(find ${REPO}/DSDT/raw/ -type f -name \*.dsl -exec sh -c 'basename {} .dsl' \; ))

    #
    # Search DptfTa.
    #
    for dslfile in ${dslfiles[@]}
    do
      grep -i "DptfTa" "${REPO}"/DSDT/raw/${dslfile}.dsl &> /dev/null && RETURN_VAL=0 || RETURN_VAL=1

      if [ "${RETURN_VAL}" == 0 ];
        then
          DptfTa=${dslfile}
      fi
    done

    #
    # Search SaSsdt.
    #
    for dslfile in ${dslfiles[@]}
    do
      grep -i "SaSsdt" "${REPO}"/DSDT/raw/${dslfile}.dsl &> /dev/null && RETURN_VAL=0 || RETURN_VAL=1

      if [ "${RETURN_VAL}" == 0 ];
        then
          SaSsdt=${dslfile}
      fi
    done

    #
    # Search SgRef.
    #
    for dslfile in ${dslfiles[@]}
    do
      grep -i "SgRef" "${REPO}"/DSDT/raw/${dslfile}.dsl &> /dev/null && RETURN_VAL=0 || RETURN_VAL=1

      if [ "${RETURN_VAL}" == 0 ];
        then
          SgRef=${dslfile}
      fi
    done

    #
    # Search OptRef.
    #
    for dslfile in ${dslfiles[@]}
    do
      grep -i "OptRef" "${REPO}"/DSDT/raw/${dslfile}.dsl &> /dev/null && RETURN_VAL=0 || RETURN_VAL=1

      if [ "${RETURN_VAL}" == 0 ];
        then
          OptRef=${dslfile}
      fi
    done
}

#
#--------------------------------------------------------------------------------
#

function _update_clover()
{
    KEXT_DIR="${gESPMountPoint}/EFI/CLOVER/kexts/${gOSVer}"

    #
    # Updating kexts. NOTE: This progress will remove any previous kexts.
    #
    _PRINT_MSG "--->: ${BLUE}Updating kexts...${OFF}"
    _tidy_exec "rm -rf ${KEXT_DIR}" "Remove previous kexts in ${KEXT_DIR}"
    _tidy_exec "cp -R ./CLOVER/kexts/${gOSVer} ${gESPMountPoint}/EFI/CLOVER/kexts/" "Update kexts from ./CLOVER/kexts/${gOSVer}"
    _tidy_exec "cp -R ./Kexts/*.kext ${KEXT_DIR}/" "Update kexts from ./Kexts"
    if [[ ${gSelect_TouchPad_Drv} == 1 ]];
      then
        #
        # Use ApplePS2SmartTouchPad, remove VoodooPS2
        #
        _tidy_exec "rm -rf ${KEXT_DIR}/VoodooPS2Controller.kext" "Install ApplePS2SmartTouchPad"
      else
        #
        # Use VoodooPS2Controller, remove ApplePS2SmartTouchPad
        #
        _tidy_exec "rm -rf ${KEXT_DIR}/ApplePS2SmartTouchPad.kext" "Install VoodooPS2Controller"
    fi

    #
    # Decide which BT kext to use.
    #
    gBluetooth_Brand_String=$(ioreg | grep -i 'BCM' | grep -i 'Apple' | sed -e 's/.*-o //' -e 's/@.*//')

    #
    # Try to build injector instead of using BrcmPatchRAM.kext
    #
    if [[ `ioreg` == *"BCM20702A3"* ]];
      then
        #
        # BCM20702A3 found.
        #
        _tidy_exec "rm -rf ${KEXT_DIR}/BrcmFirmwareRepo.kext" "BCM20702A3 found"
      else
        #
        # BCM2045A0 found. We remove BrcmFirmwareData.kext to prevent this driver crashes the whole system during boot.
        #
        _tidy_exec "rm -rf ${KEXT_DIR}/BrcmFirmwareData.kext" "BCM2045A0 found"
    fi

    #
    # Decide which kext to be installed for BT.
    #
    if [[ $gMINOR_VER -ge 11 ]];
      then
        #
        # OS X is 10.11+.
        #
        _tidy_exec "rm -rf ${KEXT_DIR}/BrcmPatchRAM.kext" "Remove redundant BT driver::BrcmPatchRAM.kext"
      else
        #
        # OS X is 10.10-.
        #
        _tidy_exec "rm -rf ${KEXT_DIR}/BrcmPatchRAM2.kext" "Remove redundant BT driver::BrcmPatchRAM2.kext"
    fi

    #
    # gEFI.
    #
    drvEFI=("FSInject-64.efi" "HFSPlus.efi" "OsxAptioFix2Drv-64.efi" "OsxFatBinaryDrv-64.efi" "DataHubDxe-64.efi")
    efiTOOL=("Shell.inf" "Shell32.efi" "Shell64.efi" "Shell64U.efi" "bdmesg.efi")

    #
    # Check if necessary to update Clover.
    #
    for filename in "${drvEFI[@]}"
    do
      _updfl "${t_drivers64UEFI}/${filename}" "${drivers64UEFI}/${filename}"
    done

    for filename in "${efiTOOL[@]}"
    do
      _updfl "${t_clover_tools}/${filename}" "${clover_tools}/${filename}"
    done

    #
    # Update CLOVERX64.efi
    #
    _updfl "${gESPMountPoint}/EFI/CLOVER/CLOVERX64.efi" "${REPO}/CLOVER/CLOVERX64.efi"
}

#
#--------------------------------------------------------------------------------
#

function _updfl()
{
    local gTargetf=$1
    local gSourcef=$2
    local gTargetHash=""
    local gSourceHash=""

    if [ -f ${gTargetf} ]; then
        gTargetHash=$(md5 -q $gTargetf)
    fi

    if [ -f ${gSourcef} ]; then
        gSourceHash=$(md5 -q $gSourcef)
    fi

    if [[ "${gTargetHash}" != "${gSourceHash}" ]]; then
        #
        # Both target and source file exist, update target file
        #
        _tidy_exec "cp ${gSourcef} ${gTargetf}" "Update ${gTargetf}"
    fi
}

#
#--------------------------------------------------------------------------------
#

function _update_thm()
{
    if [ -d "${gESPMountPoint}/EFI/CLOVER/themes/bootcamp" ];
      then
        if [[ `cat "${gESPMountPoint}/EFI/CLOVER/themes/bootcamp/theme.plist"` != *"syscl"* ]];
          then
            #
            # Yes we need to update themes.
            #
            _del "${gESPMountPoint}/EFI/CLOVER/themes/bootcamp"
            cp -R "${REPO}/CLOVER/themes/BootCamp" "${gESPMountPoint}/EFI/CLOVER/themes"
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
    echo '		<string>-w /etc/sysclusbfix.wake</string>'                                                                                                 >> "$gUSBSleepConfig"
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
    echo 'gMountPartition="/tmp/com.syscl.externalfix"'                                                                                                     >> "$gUSBSleepScript"
    echo 'gDisk=($(diskutil list | grep -i "External" | sed -e "s| (external, physical):||" -e "s|\/dev\/||"))'                                             >> "$gUSBSleepScript"
    echo ''                                                                                                                                                 >> "$gUSBSleepScript"
    echo 'for ((i=0; i<${#gDisk[@]}; ++i))'                                                                                                                 >> "$gUSBSleepScript"
    echo 'do'                                                                                                                                               >> "$gUSBSleepScript"
    echo '  gCurrent_Partitions=($(diskutil list ${gDisk[i]} |grep -o "disk[0-9]s[0-9]"))'                                                                  >> "$gUSBSleepScript"
    echo '  for ((k=0; k<${#gCurrent_Partitions[@]}; ++k))'                                                                                                 >> "$gUSBSleepScript"
    echo '  do'                                                                                                                                             >> "$gUSBSleepScript"
    echo '    gConfirm_Mounted=$(diskutil info ${gCurrent_Partitions[k]} |grep -i 'Mounted' |sed -e "s| Mounted:||" -e "s| ||g")'                           >> "$gUSBSleepScript"
    echo '    if [[ ${gConfirm_Mounted} == *"Yes"* ]];'                                                                                                     >> "$gUSBSleepScript"
    echo '      then'                                                                                                                                       >> "$gUSBSleepScript"
    echo '        echo ${gCurrent_Partitions[k]} >> ${gMountPartition}'                                                                                     >> "$gUSBSleepScript"
    echo '    fi'                                                                                                                                           >> "$gUSBSleepScript"
    echo '  done'                                                                                                                                           >> "$gUSBSleepScript"
    echo 'done'                                                                                                                                             >> "$gUSBSleepScript"
    echo 'diskutil list | grep -i "External" | sed -e "s| (external, physical):||" | xargs -I {} diskutil eject {}'                                         >> "$gUSBSleepScript"
    echo ''                                                                                                                                                 >> "$gUSBSleepScript"
    #
    # Add detection for RTLWlan USB
    #
    echo '#'                                                                                                                                                >> "$gUSBSleepScript"
    echo '# Fix RTLWlanUSB sleep problem credit B1anker & syscl/lighting/Yating Zhou. @PCBeta.'                                                             >> "$gUSBSleepScript"
    echo '#'                                                                                                                                                >> "$gUSBSleepScript"
    echo ''                                                                                                                                                 >> "$gUSBSleepScript"
    echo "gRTWlan_kext=$(echo $gRTWlan_kext)"                                                                                                               >> "$gUSBSleepScript"
    echo 'gMAC_adr=$(ioreg -rc $gRTWlan_kext | sed -n "/IOMACAddress/ s/.*= <\(.*\)>.*/\1/ p")'                                                             >> "$gUSBSleepScript"
    echo ''                                                                                                                                                 >> "$gUSBSleepScript"
    echo 'if [[ "$gMAC_adr" != 0 ]];'                                                                                                                       >> "$gUSBSleepScript"
    echo '  then'                                                                                                                                           >> "$gUSBSleepScript"
    echo '    gRT_Config="/Applications/Wireless Network Utility.app"/${gMAC_adr}rfoff.rtl'                                                                 >> "$gUSBSleepScript"
    echo ''                                                                                                                                                 >> "$gUSBSleepScript"
    echo '    if [ ! -f $gRT_Config ];'                                                                                                                     >> "$gUSBSleepScript"
    echo '      then'                                                                                                                                       >> "$gUSBSleepScript"
    echo '        gRT_Config=$(ls "/Applications/Wireless Network Utility.app"/*rfoff.rtl)'                                                                 >> "$gUSBSleepScript"
    echo '    fi'                                                                                                                                           >> "$gUSBSleepScript"
    echo ''                                                                                                                                                 >> "$gUSBSleepScript"
    echo "    osascript -e 'quit app \"Wireless Network Utility\"'"                                                                                         >> "$gUSBSleepScript"
    echo '    echo "1" > "$gRT_Config"'                                                                                                                     >> "$gUSBSleepScript"
    echo '    open "/Applications/Wireless Network Utility.app"'                                                                                            >> "$gUSBSleepScript"
    echo 'fi'                                                                                                                                               >> "$gUSBSleepScript"
}

#
#--------------------------------------------------------------------------------
#

function _RTLWlanU()
{
    _del ${gUSBWakeScript}
    _del "/etc/syscl.usbfix.wake"

    #
    # Add detection for RTLWlan USB
    #
    echo '#!/bin/sh'                                                                                                                                         > "$gUSBWakeScript"
    echo '#'                                                                                                                                                >> "$gUSBWakeScript"
    echo '# Added mount Disk for "OS X" (c) syscl/lighting/Yating Zhou.'                                                                                    >> "$gUSBWakeScript"
    echo '#'                                                                                                                                                >> "$gUSBWakeScript"
    echo ''                                                                                                                                                 >> "$gUSBWakeScript"
    echo 'gMountPartition="/tmp/com.syscl.externalfix"'                                                                                                     >> "$gUSBWakeScript"
    echo ''                                                                                                                                                 >> "$gUSBWakeScript"
    echo 'cat ${gMountPartition} |xargs -I {} diskutil mount {}'                                                                                            >> "$gUSBWakeScript"
    echo 'rm ${gMountPartition}'                                                                                                                            >> "$gUSBWakeScript"
    echo ''                                                                                                                                                 >> "$gUSBWakeScript"
    echo '#'                                                                                                                                                >> "$gUSBWakeScript"
    echo '# Fix RTLWlanUSB sleep problem credit B1anker & syscl/lighting/Yating Zhou. @PCBeta.'                                                             >> "$gUSBWakeScript"
    echo '#'                                                                                                                                                >> "$gUSBWakeScript"
    echo ''                                                                                                                                                 >> "$gUSBWakeScript"
    echo "gRTWlan_kext=$(echo $gRTWlan_kext)"                                                                                                               >> "$gUSBWakeScript"
    echo 'gMAC_adr=$(ioreg -rc $gRTWlan_kext | sed -n "/IOMACAddress/ s/.*= <\(.*\)>.*/\1/ p")'                                                             >> "$gUSBWakeScript"
    echo ''                                                                                                                                                 >> "$gUSBWakeScript"
    echo 'if [[ "$gMAC_adr" != 0 ]];'                                                                                                                       >> "$gUSBWakeScript"
    echo '  then'                                                                                                                                           >> "$gUSBWakeScript"
    echo '    gRT_Config="/Applications/Wireless Network Utility.app"/${gMAC_adr}rfoff.rtl'                                                                 >> "$gUSBWakeScript"
    echo ''                                                                                                                                                 >> "$gUSBWakeScript"
    echo '    if [ ! -f $gRT_Config ];'                                                                                                                     >> "$gUSBWakeScript"
    echo '      then'                                                                                                                                       >> "$gUSBWakeScript"
    echo '        gRT_Config=$(ls "/Applications/Wireless Network Utility.app"/*rfoff.rtl)'                                                                 >> "$gUSBWakeScript"
    echo '    fi'                                                                                                                                           >> "$gUSBWakeScript"
    echo ''                                                                                                                                                 >> "$gUSBWakeScript"
    echo "    osascript -e 'quit app \"Wireless Network Utility\"'"                                                                                         >> "$gUSBWakeScript"
    echo '    echo "0" > "$gRT_Config"'                                                                                                                     >> "$gUSBWakeScript"
    echo '    open "/Applications/Wireless Network Utility.app"'                                                                                            >> "$gUSBWakeScript"
    echo 'fi'                                                                                                                                               >> "$gUSBWakeScript"
}

#
#--------------------------------------------------------------------------------
#

function _fnd_RTW_Repo()
{
    if [ -z $gRTWlan_kext ];
      then
        #
        # RTWlan_kext is not in /Library/Extensions. Check /S*/L*/E*.
        #
        gRTWlan_kext=$(ls /System/Library/Extensions | grep -i "Rtw" | sed 's/.kext//')
        gRTWlan_Repo="/System/Library/Extensions"
    fi
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

function _fix_usb_ejected_improperly()
{
    #
    # Generate configuration file of sleepwatcher launch demon.
    #
    _tidy_exec "_printUSBSleepConfig" "Generate configuration file of sleepwatcher launch daemon"

    #
    # Find RTW place.
    #
    _fnd_RTW_Repo

    #
    # Generate script to unmount external devices before sleep (c) syscl/lighting/Yating Zhou.
    #
    _tidy_exec "_createUSB_Sleep_Script" "Generating script to unmount external devices before sleep (c) syscl/lighting/Yating Zhou"

    #
    # Generate script to load RTWlanUSB upon sleep.
    #
    _tidy_exec "_RTLWlanU" "Generate script to load RTWlanUSB upon sleep"

    #
    # Install sleepwatcher daemon.
    #
    _PRINT_MSG "--->: Installing external devices sleep patch..."
    sudo mkdir -p "${gInstall_Repo}"
    _tidy_exec "sudo cp "${gFrom}/sleepwatcher" "${gInstall_Repo}"" "Install sleepwatcher daemon"
    _tidy_exec "sudo cp "${gUSBSleepConfig}" "${to_Plist}"" "Install configuration of sleepwatcher daemon"
    _tidy_exec "sudo cp "${gUSBSleepScript}" "${to_shell_sleep}"" "Install sleep script"
    _tidy_exec "sudo cp "${gUSBWakeScript}" "${to_shell_wake}"" "Install wake script"
    _tidy_exec "sudo chmod 744 ${to_shell_sleep}" "Fix the permissions of ${to_shell_sleep}"
    _tidy_exec "sudo chmod 744 ${to_shell_wake}" "Fix the permissions of ${to_shell_wake}"
    _tidy_exec "sudo launchctl load ${to_Plist}" "Trigger startup service of syscl.usb.fix"

    #
    # Clean up.
    #
    _tidy_exec "rm $gConfig $gUSBSleepScript" "Clean up"
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
    if [[ "$gArgv" != *"-NO-UPDATE"* ]];
      then
        _update
    fi

    #
    # Generate dir.
    #
    _tidy_exec "_touch "${REPO}/DSDT"" "Create ./DSDT"
    _tidy_exec "_touch "${prepare}"" "Create ./DSDT/prepare"
    _tidy_exec "_touch "${precompile}"" "Create ./DSDT/precompile"
    _tidy_exec "_touch "${compile}"" "Create ./DSDT/compile"

    #
    # Mount esp.
    #
    diskutil list
    printf "Enter ${RED}EFI's${OFF} IDENTIFIER, e.g. ${BOLD}disk0s1${OFF}"
    read -p ": " targetEFI
    if [ $gMINOR_VER -ge 14 ]; then
        #
        # 10.14+
        #
        _tidy_exec "sudo diskutil mount ${targetEFI}" "Mount ${targetEFI}"
    else
        _tidy_exec "diskutil mount ${targetEFI}" "Mount ${targetEFI}"
    fi
    _getESPMntPoint ${targetEFI}
    _setESPVariable

    #
    # Copy origin aml to raw.
    #
    if [ -f "${gESPMountPoint}/EFI/CLOVER/ACPI/origin/DSDT.aml" ];
      then
        local gOrgAcpiRepo="${gESPMountPoint}/EFI/CLOVER/ACPI/origin"
        _tidy_exec "cp "${gOrgAcpiRepo}/DSDT.aml" "${gOrgAcpiRepo}/SSDT-*.aml" "${decompile}"" "Copy untouch ACPI tables"
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
    # Choose touchpad kext you prefer
    #
    printf "Available touchpad kext:\n"
    printf "[   ${BLUE}1${OFF}  ] ApplePS2SmartTouchPad\n"
    printf "[   ${BLUE}2${OFF}  ] VoodooPS2Controller\n"
    printf "Please choose the desired touchpad kext (${RED}1${OFF} or ${RED}2${OFF})"
    read -p ": " gSelect_TouchPad_Drv
    case "${gSelect_TouchPad_Drv}" in
      1     ) _PRINT_MSG "NOTE: Use ${BLUE}ApplePS2SmartTouchPad${OFF}"
              ;;

      2     ) _PRINT_MSG "NOTE: Use ${BLUE}VoodooPS2Controller${OFF}"
              ;;

      *     ) _PRINT_MSG "NOTE: Invalid number, use default setting"
              local gApplePS2SmartTouchPadIsPresent=$(kextstat |grep -i "ApplePS2SmartTouchPad")
              if [[ ${gApplePS2SmartTouchPadIsPresent} != "" ]];
                then
                  #
                  # Use ApplePS2SmartTouchPad
                  #
                  gSelect_TouchPad_Drv=1
                else
                  #
                  # Use VoodooPS2Controller
                  #
                  gSelect_TouchPad_Drv=2
              fi
              ;;
    esac

    #
    # Decompile acpi tables
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
    _tidy_exec "patch_acpi DSDT syscl "audio_HDEF-layout1"" "Inject Audio Info"
    _tidy_exec "patch_acpi DSDT syscl "audio_B0D3_HDAU"" "Rename B0D3 to HDAU"
    _tidy_exec "patch_acpi DSDT syscl "remove_glan"" "Remove GLAN device"
    _tidy_exec "patch_acpi DSDT syscl "syscl_iGPU_MEM2"" "iGPU TPMX to MEM2"
    _tidy_exec "patch_acpi DSDT syscl "syscl_IMTR2TIMR"" "IMTR->TIMR, _T_x->T_x"
#   _tidy_exec "patch_acpi DSDT syscl "syscl_ALSD2ALS0"" "ALSD->ALS0"
    #
    # Modificate ACPI for macOS to load devices correctly
    #
    _tidy_exec "patch_acpi DSDT syscl "syscl_SLPB"" "Insert SLPB"
    _tidy_exec "patch_acpi DSDT syscl "syscl_PMCR"" "Insert PMCR"
    _tidy_exec "patch_acpi DSDT syscl "syscl_PPMC"" "Insert PPMC"
    # Inject reg-ltrovr for IOPCIFamily::setLatencyTolerance setting ltrOffset for PCI devices successfully (c) syscl
    #_tidy_exec "patch_acpi DSDT syscl "syscl_ltrovr"" "Inject reg-ltrovr for IOPCIFamily::setLatencyTolerance setting ltrOffset for PCI devices successfully (c) syscl"
    #
    # Added deep sleep & deep idle as per Pike R. Alpha
    #
    #_tidy_exec "patch_acpi DSDT syscl "system_deep_idle"" "Added deep sleep and deep idle properties"

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
    _tidy_exec "patch_acpi ${SaSsdt} syscl "syscl_Haswell_DPnHDMI"" "Insert HDAU device (c) syscl"
    #
    # Note this condition else-if use to fix issue #54 by edfungus
    #
    # Usually SgRef and OptRef are for integrate card and discrete card, but edfungus' device lack them
    # SgRef Patches.
    #
    if [ -f "${REPO}/DSDT/raw/${SgRef}.dsl" ]; then
        _PRINT_MSG "--->: ${BLUE}Patching ${SgRef}.dsl${OFF}"
        _tidy_exec "patch_acpi ${SgRef} graphics "graphics_Rename-GFX0"" "Rename GFX0 to IGPU"
    fi
    #
    # OptRef Patches.
    #
    if [ -f "${REPO}/DSDT/raw/${OptRef}.dsl" ]; then
        _PRINT_MSG "--->: ${BLUE}Patching ${OptRef}.dsl${OFF}"
        _tidy_exec "patch_acpi ${OptRef} syscl "WMMX-invalid-operands"" "Remove invalid operands"
        _tidy_exec "patch_acpi ${OptRef} graphics "graphics_Rename-GFX0"" "Rename GFX0 to IGPU"
        _tidy_exec "patch_acpi ${OptRef} syscl "graphics_Disable_Nvidia"" "Disable Nvidia card (Non-operational in OS X)"
    fi

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
    #
    # Note this condition else-if use to fix issue #54 by edfungus
    #
    # Usually SgRef and OptRef are for integrate card and discrete card, but edfungus' device lack them
    # SgRef Patches.
    #
    if [ -f "${REPO}/DSDT/raw/${SgRef}.dsl" ]; then
        _tidy_exec "compile_table "${SgRef}"" "Compile SgRef"
    fi

    if [ -f "${REPO}/DSDT/raw/${OptRef}.dsl" ]; then
        _tidy_exec "compile_table "${OptRef}"" "Compile OptRef"
    fi

    #
    # Copy SSDT-rmne.aml.
    #
    _PRINT_MSG "--->: ${BLUE}Copying SSDT-rmne.aml to ./DSDT/compile...${OFF}"
    _tidy_exec "cp "${prepare}"/SSDT-rmne.aml "${compile}"" "Copy SSDT-rmne.aml to ./DSDT/compile"

    #
    # Install SSDT-m for ALS0.
    #
    _PRINT_MSG "--->: ${BLUE}Installing SSDT-m-M3800.aml to ./DSDT/compile...${OFF}"
    _tidy_exec "cp "${prepare}"/SSDT-m-M3800.aml "${compile}"" "Copy SSDT-m-M3800.aml to ./DSDT/compile"

    #
    # Clean up dynamic SSDTs.
    #
    _tidy_exec "rm "${compile}"SSDT-x*.aml" "Clean dynamic SSDTs"

    #
    # Copy AML to destination place.
    #
    _tidy_exec "_touch "${gESPMountPoint}/EFI/CLOVER/ACPI/patched"" "Create ${gESPMountPoint}/EFI/CLOVER/ACPI/patched"
    _tidy_exec "cp "${compile}"*.aml ${gESPMountPoint}/EFI/CLOVER/ACPI/patched" "Copy tables to ${gESPMountPoint}/EFI/CLOVER/ACPI/patched"

    #
    # Refresh kext in Clover.
    #
    _update_clover

    #
    # Refresh BootCamp theme.
    #
    _update_thm

    #
    # Remove old patched HDA kext if exists.
    #
    _PRINT_MSG "--->: ${BLUE}Cleaning up old patched HDA kext if exists...${OFF}"
    _tidy_exec "remove_patched_hda_kext" "Clean up old patched HDA kext if exists"

    #
    # Fix Clover's configuration for old config.plist compatible.
    #
    _PRINT_MSG "--->: ${BLUE}Fixing Clover's configuration...${OFF}"
    _tidy_exec "_check_and_fix_config" "Fix Clover's configuration"

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
    # Rebuild dyld_shared_cache to resolve display framework issues
    #
    _tidy_exec "sudo update_dyld_shared_cache -force" "Update dyld shared cache"

    #
    # Clean up backup
    #
    _del "${gESPMountPoint}/EFI/CLOVER/config.plistg"

    _PRINT_MSG "NOTE: Congratulations! All operation has been completed"
    _PRINT_MSG "NOTE: Reboot now. Then enjoy your OS X! -${BOLD}syscl/lighting/Yating Zhou @PCBeta${OFF}"
}

#==================================== START =====================================

main "$@"

#================================================================================

exit ${RETURN_VAL}
