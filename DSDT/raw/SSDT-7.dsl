/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20141107-64 [Jan  2 2015]
 * Copyright (c) 2000 - 2014 Intel Corporation
 * 
 * Disassembling to non-symbolic legacy ASL operators
 *
 * Disassembly of /Users/lighting/Desktop/3800 project/my/M3800/DSDT/raw/SSDT-7.aml, Tue Aug 25 18:13:24 2015
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x000002DE (734)
 *     Revision         0x01
 *     Checksum         0xC2
 *     OEM ID           "PmRef"
 *     OEM Table ID     "Cpu0Tst"
 *     OEM Revision     0x00003000 (12288)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20120711 (538052369)
 */
DefinitionBlock ("/Users/lighting/Desktop/3800 project/my/M3800/DSDT/raw/SSDT-7.aml", "SSDT", 1, "PmRef", "Cpu0Tst", 0x00003000)
{

    External (_PR_.CFGD, FieldUnitObj)
    External (_PR_.CPU0, ProcessorObj)
    External (_PR_.CPU0._PSS, PkgObj)
    External (PDC0, IntObj)
    External (TCNT, FieldUnitObj)

    Scope (\_PR.CPU0)
    {
        Name (_TPC, Zero)  // _TPC: Throttling Present Capabilities
        Method (_PTC, 0, NotSerialized)  // _PTC: Processor Throttling Control
        {
            If (And (PDC0, 0x04))
            {
                Return (Package (0x02)
                {
                    ResourceTemplate ()
                    {
                        Register (FFixedHW, 
                            0x00,               // Bit Width
                            0x00,               // Bit Offset
                            0x0000000000000000, // Address
                            ,)
                    }, 

                    ResourceTemplate ()
                    {
                        Register (FFixedHW, 
                            0x00,               // Bit Width
                            0x00,               // Bit Offset
                            0x0000000000000000, // Address
                            ,)
                    }
                })
            }

            Return (Package (0x02)
            {
                ResourceTemplate ()
                {
                    Register (SystemIO, 
                        0x05,               // Bit Width
                        0x00,               // Bit Offset
                        0x0000000000001810, // Address
                        ,)
                }, 

                ResourceTemplate ()
                {
                    Register (SystemIO, 
                        0x05,               // Bit Width
                        0x00,               // Bit Offset
                        0x0000000000001810, // Address
                        ,)
                }
            })
        }

        Name (TSMF, Package (0x10)
        {
            Package (0x05)
            {
                0x64, 
                0x03E8, 
                Zero, 
                Zero, 
                Zero
            }, 

            Package (0x05)
            {
                0x5E, 
                0x03AC, 
                Zero, 
                0x1F, 
                Zero
            }, 

            Package (0x05)
            {
                0x58, 
                0x0370, 
                Zero, 
                0x1E, 
                Zero
            }, 

            Package (0x05)
            {
                0x52, 
                0x0334, 
                Zero, 
                0x1D, 
                Zero
            }, 

            Package (0x05)
            {
                0x4B, 
                0x02F8, 
                Zero, 
                0x1C, 
                Zero
            }, 

            Package (0x05)
            {
                0x45, 
                0x02BC, 
                Zero, 
                0x1B, 
                Zero
            }, 

            Package (0x05)
            {
                0x3F, 
                0x0280, 
                Zero, 
                0x1A, 
                Zero
            }, 

            Package (0x05)
            {
                0x39, 
                0x0244, 
                Zero, 
                0x19, 
                Zero
            }, 

            Package (0x05)
            {
                0x32, 
                0x0208, 
                Zero, 
                0x18, 
                Zero
            }, 

            Package (0x05)
            {
                0x2C, 
                0x01CC, 
                Zero, 
                0x17, 
                Zero
            }, 

            Package (0x05)
            {
                0x26, 
                0x0190, 
                Zero, 
                0x16, 
                Zero
            }, 

            Package (0x05)
            {
                0x20, 
                0x0154, 
                Zero, 
                0x15, 
                Zero
            }, 

            Package (0x05)
            {
                0x19, 
                0x0118, 
                Zero, 
                0x14, 
                Zero
            }, 

            Package (0x05)
            {
                0x13, 
                0xDC, 
                Zero, 
                0x13, 
                Zero
            }, 

            Package (0x05)
            {
                0x0D, 
                0xA0, 
                Zero, 
                0x12, 
                Zero
            }, 

            Package (0x05)
            {
                0x07, 
                0x64, 
                Zero, 
                0x11, 
                Zero
            }
        })
        Name (TSMC, Package (0x08)
        {
            Package (0x05)
            {
                0x64, 
                0x03E8, 
                Zero, 
                Zero, 
                Zero
            }, 

            Package (0x05)
            {
                0x58, 
                0x036B, 
                Zero, 
                0x1E, 
                Zero
            }, 

            Package (0x05)
            {
                0x4B, 
                0x02EE, 
                Zero, 
                0x1C, 
                Zero
            }, 

            Package (0x05)
            {
                0x3F, 
                0x0271, 
                Zero, 
                0x1A, 
                Zero
            }, 

            Package (0x05)
            {
                0x32, 
                0x01F4, 
                Zero, 
                0x18, 
                Zero
            }, 

            Package (0x05)
            {
                0x26, 
                0x0177, 
                Zero, 
                0x16, 
                Zero
            }, 

            Package (0x05)
            {
                0x19, 
                0xFA, 
                Zero, 
                0x14, 
                Zero
            }, 

            Package (0x05)
            {
                0x0D, 
                0x7D, 
                Zero, 
                0x12, 
                Zero
            }
        })
        Name (TSSF, Zero)
        Mutex (TSMO, 0x00)
        Method (_TSS, 0, NotSerialized)  // _TSS: Throttling Supported States
        {
            If (LAnd (LNot (TSSF), CondRefOf (_PSS)))
            {
                Acquire (TSMO, 0xFFFF)
                If (LAnd (LNot (TSSF), CondRefOf (_PSS)))
                {
                    Name (LFMI, Zero)
                    Store (SizeOf (_PSS), LFMI)
                    Decrement (LFMI)
                    Name (LFMP, Zero)
                    Store (DerefOf (Index (DerefOf (Index (_PSS, LFMI)), One)), LFMP)
                    Store (Zero, Local0)
                    If (And (CFGD, 0x2000))
                    {
                        Store (RefOf (TSMF), Local1)
                        Store (SizeOf (TSMF), Local2)
                    }
                    Else
                    {
                        Store (RefOf (TSMC), Local1)
                        Store (SizeOf (TSMC), Local2)
                    }

                    While (LLess (Local0, Local2))
                    {
                        Store (Divide (Multiply (LFMP, Subtract (Local2, Local0)), Local2, ), 
                            Local4)
                        Store (Local4, Index (DerefOf (Index (DerefOf (Local1), Local0)), One))
                        Increment (Local0)
                    }

                    Store (Ones, TSSF)
                }

                Release (TSMO)
            }

            If (And (CFGD, 0x2000))
            {
                Return (TSMF)
            }
            Else
            {
                Return (TSMC)
            }
        }

        Method (_TSD, 0, NotSerialized)  // _TSD: Throttling State Dependencies
        {
            If (LNot (And (PDC0, 0x04)))
            {
                Return (Package (0x01)
                {
                    Package (0x05)
                    {
                        0x05, 
                        Zero, 
                        Zero, 
                        0xFD, 
                        TCNT
                    }
                })
            }

            Return (Package (0x01)
            {
                Package (0x05)
                {
                    0x05, 
                    Zero, 
                    Zero, 
                    0xFC, 
                    One
                }
            })
        }
    }
}

