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

create_dir()
{
    if [ ! -d "$1" ];then
    echo "${BLUE}[Creating directory]${OFF}: $1"
    mkdir "$1"
    fi
}

patch_acpi()
{
#   echo "${BLUE}[$2]${OFF} $3"
    if [ "$2" == "syscl" ]
    then
    "${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/$1.dsl "${REPO}"/DSDT/patches/$3.txt "${REPO}"/DSDT/raw/$1.dsl
    else
    "${REPO}"/tools/patchmatic "${REPO}"/DSDT/raw/$1.dsl "${REPO}"/DSDT/patches/$2/$3.txt "${REPO}"/DSDT/raw/$1.dsl
    fi
}

status()
{
    $1 >./DSDT/report 2>&1
#
# ------------------------------------------------:----------------------------------------------------------:------------------------------
# `grep -i "Error" ./DSDT/report` == *"0 Errors"* : `grep -i "patch complete" ./DSDT/report` == *"complete"* : ! `test -s ./DSDT/report`
# ------------------------------------------------:----------------------------------------------------------:------------------------------
#         iasl failure                            :             patchmatic failure                           : cp, rm, grep, touch, mk...
# ------------------------------------------------:----------------------------------------------------------:------------------------------
#
    if [[ `grep -i "Error" ./DSDT/report` == *"0 Errors"* || `grep -i "patch complete" ./DSDT/report` == *"complete"* || ! `test -s ./DSDT/report` ]]
    then
    echo "[   ${GREEN}OK${OFF}   ] $2."
    else
    echo "[ ${RED}FAILED${OFF} ] $2."
    grep -i -E "Error    |patchmatic|cp" ./DSDT/report >./DSDT/report.tmp
    cat ./DSDT/report.tmp
    fi
    rm ./DSDT/report.tmp ./DSDT/report &> /dev/null
}

compile_table()
{
    echo "${BLUE}[Compiling]${OFF}: $1.dsl"
    "${REPO}"/tools/iasl -vr -w1 -ve -p "${compile}"$1.aml "${precompile}"$1.dsl
}

#
# Generate define directionaries
#
status "create_dir "${REPO}/DSDT"" "Create ./DSDT"
status "create_dir "${prepare}"" "Create ./DSDT/prepare"
status "create_dir "${precompile}"" "Create ./DSDT/precompile"
status "create_dir "${compile}"" "Create ./DSDT/compile"

#
# Decompile dsdt
#
cd "${REPO}"
echo "[${RED}*${OFF}       ] ${BLUE}Disassembling tables.${OFF}"
status ""${REPO}"/tools/iasl -w1 -da -dl "${REPO}"/DSDT/raw/DSDT.aml "${REPO}"/DSDT/raw/SSDT-*.aml" "Disassemble tables"


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
# DSDT Patches
########################

echo "[${RED}**${OFF}      ] ${BLUE}Patching DSDT.dsl${OFF}"

status "patch_acpi DSDT syntax "fix_PARSEOP_ZERO"" "Fix PARSEOP_ZERO"
status "patch_acpi DSDT syntax "fix_ADBG"" "Fix ADBG Error"
status "patch_acpi DSDT graphics "graphics_Rename-GFX0"" "Rename GFX0 to IGPU"
status "patch_acpi DSDT usb "usb_7-series"" "7-series/8-series USB"
status "patch_acpi DSDT battery "battery_Acer-Aspire-E1-571"" "Acer Aspire E1-571"
status "patch_acpi DSDT system "system_IRQ"" "IRQ Fix"
status "patch_acpi DSDT system "system_SMBUS"" "SMBus Fix"
status "patch_acpi DSDT system "system_OSYS"" "OS Check Fix"
status "patch_acpi DSDT system "system_ADP1"" "AC Adapter Fix"
status "patch_acpi DSDT system "system_MCHC"" "Add MCHC"
status "patch_acpi DSDT system "system_WAK2"" "Fix _WAK Arg0 v2"
status "patch_acpi DSDT system "system_IMEI"" "Add IMEI"
status "patch_acpi DSDT system "system_Mutex"" "Fix Non-zero Mutex"
status "patch_acpi DSDT misc "misc_Haswell-LPC"" "Add Haswell LPC"
status "patch_acpi DSDT syscl "audio_HDEF-layout1"" "Add audio Layout 1"
status "patch_acpi DSDT syscl "audio_B0D3_HDAU"" "Rename B0D3 to HDAU"
status "patch_acpi DSDT syscl "remove_glan"" "Remove GLAN device"

########################
# DptfTa Patches
########################

#echo "${BLUE}[DptfTa]${OFF}: Patching ${DptfTa}.dsl in "${REPO}"/DSDT/raw"
echo "[${RED}***${OFF}     ] ${BLUE}Patching ${DptfTa}.dsl${OFF}"
status "patch_acpi ${DptfTa} syscl "_BST-package-size"" "_BST package size"
status "patch_acpi ${DptfTa} graphics "graphics_Rename-GFX0"" "Rename GFX0 to IGPU"

########################
# SaSsdt Patches
########################

echo "[${RED}****${OFF}    ] ${BLUE}Patching ${SaSsdt}.dsl${OFF}"

status "patch_acpi ${SaSsdt} graphics "graphics_Rename-GFX0"" "Rename GFX0 to IGPU"
status "patch_acpi ${SaSsdt} syscl "syscl_Iris_Pro"" "Rename HD4600 to Iris Pro"
status "patch_acpi ${SaSsdt} graphics "graphics_PNLF_haswell"" "Brightness fix (Haswell)"
status "patch_acpi ${SaSsdt} syscl "audio_B0D3_HDAU"" "Rename B0D3 to HDAU"
status "patch_acpi ${SaSsdt} syscl "audio_Intel_HD4600"" "Insert HDAU device"

########################
# SgRef Patches
########################

echo "[${RED}*****${OFF}   ] ${BLUE}Patching ${SgRef}.dsl${OFF}"
status "patch_acpi ${SgRef} graphics "graphics_Rename-GFX0"" "Rename GFX0 to IGPU"

########################
# OptRef Patches
########################

#echo "${BLUE}[OptRef]${OFF}: Patching SSDT-15 in "${REPO}"/DSDT/raw"
echo "[${RED}******${OFF}  ] ${BLUE}Patching ${OptRef}.dsl${OFF}"
status "patch_acpi ${OptRef} syscl "WMMX-invalid-operands"" "Remove invalid operands"
status "patch_acpi ${OptRef} graphics "graphics_Rename-GFX0"" "Rename GFX0 to IGPU"
status "patch_acpi ${OptRef} syscl "graphics_Disable_Nvidia"" "Disable Nvidia card (Non-operational in OS X)"

########################
# Copying all tables to precompile.
########################

echo "[${RED}*******${OFF} ] ${BLUE}Copying tables to precompile${OFF}."
status "cp "${raw}/"*.dsl "${precompile}"" "Copy tables to precompile"

########################
# Compiling tables
########################

echo "[${RED}********${OFF}] ${BLUE}Compiling tables${OFF}."
status "compile_table "DSDT"" "Compiling DSDT"
status "compile_table "${DptfTa}"" "Compiling DptfTa"
status "compile_table "${SaSsdt}"" "Compiling SaSsdt"
status "compile_table "${SgRef}"" "Compiling SgRef"
status "compile_table "${OptRef}"" "Compiling OptRef"

exit 0