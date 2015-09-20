/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20141107-64 [Jan  2 2015]
 * Copyright (c) 2000 - 2014 Intel Corporation
 * 
 * Disassembling to non-symbolic legacy ASL operators
 *
 * Disassembly of /Users/lighting/Desktop/3800 project/my/M3800/DSDT/raw/SSDT-0.aml, Tue Aug 25 18:13:23 2015
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x00000C9A (3226)
 *     Revision         0x01
 *     Checksum         0xC3
 *     OEM ID           "TrmRef"
 *     OEM Table ID     "PtidDevc"
 *     OEM Revision     0x00001000 (4096)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20091112 (537465106)
 */
DefinitionBlock ("/Users/lighting/Desktop/3800 project/my/M3800/DSDT/raw/SSDT-0.aml", "SSDT", 1, "TrmRef", "PtidDevc", 0x00001000)
{

    External (_TZ_.TZ00._TMP, MethodObj)    // 0 Arguments
    External (_TZ_.TZ01, UnknownObj)
    External (_TZ_.TZ01._TMP, MethodObj)    // 0 Arguments
    External (DTS1, FieldUnitObj)
    External (DTS2, FieldUnitObj)
    External (DTS3, FieldUnitObj)
    External (DTS4, FieldUnitObj)
    External (PAMT, FieldUnitObj)
    External (PDTS, FieldUnitObj)

    Scope (\_SB)
    {
        OperationRegion (MAIO, SystemIO, 0xFD61, 0x03)
        Field (MAIO, ByteAcc, NoLock, Preserve)
        {
            MAIN,   16, 
            MADT,   8
        }

        Method (AMBX, 3, Serialized)
        {
            If (LEqual (Arg0, Zero))
            {
                Store (Arg1, MAIN)
                Store (MADT, Local2)
                Return (Local2)
            }
            Else
            {
                Store (Arg1, MAIN)
                Store (Arg2, MADT)
                Store (Zero, Local2)
                Return (Local2)
            }
        }

        Device (PTID)
        {
            Name (_HID, EisaId ("INT340E"))  // _HID: Hardware ID
            Name (_CID, EisaId ("PNP0C02"))  // _CID: Compatible ID
            Name (IVER, 0x00030000)
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (0x0F)
            }

            Name (TSDL, Package (0x2A)
            {
                Zero, 
                "CPU Core 0 DTS", 
                Zero, 
                "CPU Core 1 DTS", 
                Zero, 
                "CPU Core 2 DTS", 
                Zero, 
                "CPU Core 3 DTS", 
                Zero, 
                "CPU Core Package DTS", 
                0x03, 
                "CPU Core VR (IMVP) Temperature", 
                0x03, 
                "Heat Exchanger Fan Temperature", 
                0x03, 
                "Skin Temperature", 
                0x03, 
                "Ambient Temperature", 
                0x02, 
                "Channel 0 DIMM Temperature", 
                0x02, 
                "Channel 1 DIMM Temperature", 
                Zero, 
                "CPU Package Temperature", 
                0x05, 
                "PCH DTS Temperature from PCH", 
                Zero, 
                "CPU PECI reading", 
                0x05, 
                "SA DTS Temperature from PCH", 
                0x02, 
                "TS-on-DIMM0 Temperature", 
                0x02, 
                "TS-on-DIMM1 Temperature", 
                0x02, 
                "TS-on-DIMM2 Temperature", 
                0x02, 
                "TS-on-DIMM3 Temperature", 
                0x02, 
                "TZ00 _TMP", 
                0x02, 
                "TZ01 _TMP"
            })
            Name (PSDL, Package (0x26)
            {
                0x0B, 
                "Platform Power (mW)", 
                0x0B, 
                "Brick Power cW(100ths)", 
                0x0B, 
                "Battery Discharge Power cW(100ths)", 
                0x0B, 
                "Platform Average Power (mW)", 
                0x0B, 
                "Brick Average Power cW(0.01)", 
                0x0B, 
                "Battery Discharge Average Power cW(0.01)", 
                0x0C, 
                "Battery 1 Design Capacity (mWh)", 
                0x0C, 
                "Battery 1 Remaining Capacity (mWh)", 
                0x0C, 
                "Battery 1 Full Charge Capacity (mWh)", 
                0x0C, 
                "Battery 1 Full Resolution Voltage (mV)", 
                0x0C, 
                "Battery 1 Full Resolution Discharge Current (mA)", 
                0x0C, 
                "Battery 1 Full Resolution Charge Current (mA)", 
                0x0C, 
                "Battery 2 Remaining Capacity (mWh)", 
                0x0C, 
                "Battery 2 Full Charge Capacity (mWh)", 
                0x0C, 
                "Battery 2 Full Resolution Voltage (mV)", 
                0x0C, 
                "Battery 2 Full Resolution Discharge Current (mA)", 
                0x0C, 
                "Battery 2 Full Resolution Charge Current (mA)", 
                0x0C, 
                "Battery Pack 1 maximum power (mW)", 
                0x0C, 
                "Battery Pack 2 maximum power (mW)"
            })
            Name (OSDL, Package (0x0F)
            {
                Zero, 
                "CPU Fan #1 Speed", 
                "RPM", 
                Zero, 
                "CPU Fan #2 Speed", 
                "RPM", 
                0x03, 
                "Skin Temp 0", 
                "RAW", 
                0x03, 
                "Thermistor 1 ", 
                "RAW", 
                0x03, 
                "Thermistor 2 ", 
                "RAW"
            })
            Method (TSDD, 0, NotSerialized)
            {
                Name (TMPV, Package (0x15)
                {
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000
                })
                Store (Add (Multiply (DTS1, 0x0A), 0x0AAC), Index (TMPV, Zero))
                Store (Add (Multiply (DTS2, 0x0A), 0x0AAC), Index (TMPV, One))
                Store (Add (Multiply (DTS3, 0x0A), 0x0AAC), Index (TMPV, 0x02))
                Store (Add (Multiply (DTS4, 0x0A), 0x0AAC), Index (TMPV, 0x03))
                Store (Add (Multiply (PDTS, 0x0A), 0x0AAC), Index (TMPV, 0x04))
                Store (\_TZ.TZ00._TMP (), Index (TMPV, 0x13))
                If (CondRefOf (\_TZ.TZ01))
                {
                    Store (\_TZ.TZ01._TMP (), Index (TMPV, 0x14))
                }

                Return (TMPV)
            }

            Method (PSDD, 0, Serialized)
            {
                Name (PWRV, Package (0x13)
                {
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000
                })
                Return (PWRV)
            }

            Method (OSDD, 0, NotSerialized)
            {
                Name (OSDV, Package (0x05)
                {
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000
                })
                Return (OSDV)
            }

            Method (SDSP, 0, NotSerialized)
            {
                Return (0x0A)
            }

            Name (PADA, Package (0x0A)
            {
                One, 
                Ones, 
                Ones, 
                0x1A, 
                Ones, 
                Ones, 
                Ones, 
                Ones, 
                Ones, 
                Ones
            })
            Name (PADD, Package (0x0A)
            {
                0x02, 
                0x06A4, 
                0x06A0, 
                0x1A, 
                0x62, 
                0x63, 
                0x60, 
                0x61, 
                0x65, 
                0x64
            })
            Method (PADT, 0, NotSerialized)
            {
                If (PAMT)
                {
                    Return (PADA)
                }

                Return (PADD)
            }

            Method (RPMD, 0, NotSerialized)
            {
                Name (MTMP, Buffer (0x1A) {})
                Store (AMBX (Zero, 0x8AFB, Zero), Local0)
                Store (AMBX (Zero, 0x8BFB, Zero), Index (MTMP, 0x05))
                Store (AMBX (Zero, 0x8CFB, Zero), Index (MTMP, 0x06))
                Store (AMBX (Zero, 0x8DFB, Zero), Index (MTMP, 0x07))
                Store (AMBX (Zero, 0x8EFB, Zero), Index (MTMP, 0x08))
                Store (AMBX (Zero, 0x8FFB, Zero), Index (MTMP, 0x09))
                Store (AMBX (Zero, 0x90FB, Zero), Index (MTMP, 0x0A))
                Store (AMBX (Zero, 0x91FB, Zero), Index (MTMP, 0x0B))
                Store (AMBX (Zero, 0x92FB, Zero), Index (MTMP, 0x0C))
                Store (AMBX (Zero, 0x93FB, Zero), Index (MTMP, 0x0D))
                Store (AMBX (Zero, 0x94FB, Zero), Index (MTMP, 0x0E))
                Store (AMBX (Zero, 0x95FB, Zero), Index (MTMP, 0x0F))
                Store (AMBX (Zero, 0x96FB, Zero), Index (MTMP, 0x10))
                Store (AMBX (Zero, 0x97FB, Zero), Index (MTMP, 0x11))
                Store (AMBX (Zero, 0x98FB, Zero), Index (MTMP, 0x12))
                Store (AMBX (Zero, 0x99FB, Zero), Index (MTMP, 0x13))
                Store (AMBX (Zero, 0x9AFB, Zero), Index (MTMP, 0x14))
                Store (AMBX (Zero, 0x9BFB, Zero), Index (MTMP, 0x15))
                Store (AMBX (Zero, 0x9CFB, Zero), Index (MTMP, 0x16))
                Store (AMBX (Zero, 0x9DFB, Zero), Index (MTMP, 0x17))
                Store (AMBX (Zero, 0x9EFB, Zero), Index (MTMP, 0x18))
                Store (AMBX (Zero, 0x9FFB, Zero), Index (MTMP, 0x19))
                Store (AMBX (Zero, 0x86FB, Zero), Index (MTMP, Zero))
                Store (AMBX (Zero, 0x87FB, Zero), Index (MTMP, One))
                Store (AMBX (Zero, 0x88FB, Zero), Index (MTMP, 0x02))
                Store (AMBX (Zero, 0x89FB, Zero), Index (MTMP, 0x03))
                Return (MTMP)
            }

            Method (WPMD, 1, NotSerialized)
            {
                If (LNotEqual (SizeOf (Arg0), 0x1A))
                {
                    Return (Ones)
                }

                AMBX (One, 0x8AFB, DerefOf (Index (Arg0, 0x04)))
                AMBX (One, 0x8BFB, DerefOf (Index (Arg0, 0x05)))
                AMBX (One, 0x8CFB, DerefOf (Index (Arg0, 0x06)))
                AMBX (One, 0x8DFB, DerefOf (Index (Arg0, 0x07)))
                AMBX (One, 0x8EFB, DerefOf (Index (Arg0, 0x08)))
                AMBX (One, 0x8FFB, DerefOf (Index (Arg0, 0x09)))
                AMBX (One, 0x90FB, DerefOf (Index (Arg0, 0x0A)))
                AMBX (One, 0x91FB, DerefOf (Index (Arg0, 0x0B)))
                AMBX (One, 0x92FB, DerefOf (Index (Arg0, 0x0C)))
                AMBX (One, 0x93FB, DerefOf (Index (Arg0, 0x0D)))
                AMBX (One, 0x94FB, DerefOf (Index (Arg0, 0x0E)))
                AMBX (One, 0x95FB, DerefOf (Index (Arg0, 0x0F)))
                AMBX (One, 0x96FB, DerefOf (Index (Arg0, 0x10)))
                AMBX (One, 0x97FB, DerefOf (Index (Arg0, 0x11)))
                AMBX (One, 0x98FB, DerefOf (Index (Arg0, 0x12)))
                AMBX (One, 0x99FB, DerefOf (Index (Arg0, 0x13)))
                AMBX (One, 0x9AFB, DerefOf (Index (Arg0, 0x14)))
                AMBX (One, 0x9BFB, DerefOf (Index (Arg0, 0x15)))
                AMBX (One, 0x9CFB, DerefOf (Index (Arg0, 0x16)))
                AMBX (One, 0x9DFB, DerefOf (Index (Arg0, 0x17)))
                AMBX (One, 0x9EFB, DerefOf (Index (Arg0, 0x18)))
                AMBX (One, 0x9FFB, DerefOf (Index (Arg0, 0x19)))
                AMBX (One, 0x86FB, DerefOf (Index (Arg0, Zero)))
                AMBX (One, 0x87FB, DerefOf (Index (Arg0, One)))
                AMBX (One, 0x88FB, DerefOf (Index (Arg0, 0x02)))
                AMBX (One, 0x89FB, DerefOf (Index (Arg0, 0x03)))
                Return (Zero)
            }

            Method (ISPC, 0, NotSerialized)
            {
                AMBX (One, 0x10FF, 0x60)
                Store (AMBX (Zero, 0x10FF, Zero), Local0)
                While (Local0)
                {
                    Store (AMBX (Zero, 0x10FF, Zero), Local0)
                }

                Return (Zero)
            }

            Method (ENPC, 0, NotSerialized)
            {
                AMBX (One, 0x10FF, 0x61)
                Store (AMBX (Zero, 0x10FF, Zero), Local0)
                While (Local0)
                {
                    Store (AMBX (Zero, 0x10FF, Zero), Local0)
                }

                Return (Zero)
            }

            Method (RPCS, 0, NotSerialized)
            {
                AMBX (One, 0x10FF, 0x65)
                Store (AMBX (Zero, 0x10FF, Zero), Local0)
                While (Local0)
                {
                    Store (AMBX (Zero, 0x10FF, Zero), Local0)
                }

                Store (AMBX (Zero, 0x80FB, Zero), Local0)
                Return (Local0)
            }

            Method (RPEC, 0, NotSerialized)
            {
                Store (Zero, Local0)
                Store (Zero, Local0)
                AMBX (One, 0x10FF, 0x64)
                Store (AMBX (Zero, 0x10FF, Zero), Local0)
                While (Local0)
                {
                    Store (AMBX (Zero, 0x10FF, Zero), Local0)
                }

                Store (AMBX (Zero, 0x82FB, Zero), Local1)
                Or (Local0, Local1, Local0)
                Store (AMBX (Zero, 0x83FB, Zero), Local1)
                Or (Local0, ShiftLeft (Local1, 0x08), Local0)
                Store (AMBX (Zero, 0x84FB, Zero), Local1)
                Or (Local0, ShiftLeft (Local1, 0x10), Local0)
                Store (AMBX (Zero, 0x85FB, Zero), Local1)
                Or (Local0, ShiftLeft (Local1, 0x18), Local0)
                Return (Local0)
            }
        }
    }
}

