/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20141107-64 [Jan  2 2015]
 * Copyright (c) 2000 - 2014 Intel Corporation
 * 
 * Disassembling to non-symbolic legacy ASL operators
 *
 * Disassembly of /Users/lighting/Desktop/3800 project/my/M3800/DSDT/raw/SSDT-9.aml, Tue Aug 25 18:13:24 2015
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x000001C7 (455)
 *     Revision         0x01
 *     Checksum         0x3E
 *     OEM ID           "PmRef"
 *     OEM Table ID     "LakeTiny"
 *     OEM Revision     0x00003000 (12288)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20120711 (538052369)
 */
DefinitionBlock ("/Users/lighting/Desktop/3800 project/my/M3800/DSDT/raw/SSDT-9.aml", "SSDT", 1, "PmRef", "LakeTiny", 0x00003000)
{

    External (_PR_.CPU0.GEAR, IntObj)
    External (_SB_.PCI0.SAT0, DeviceObj)
    External (_SB_.PCI0.SAT1, DeviceObj)
    External (MPMF, UnknownObj)
    External (PNOT, MethodObj)    // 0 Arguments

    Scope (\_SB.PCI0.SAT0)
    {
        Method (SLT1, 0, Serialized)
        {
            If (CondRefOf (\_PR.CPU0.GEAR))
            {
                Store (Zero, \_PR.CPU0.GEAR)
                \PNOT ()
            }

            Return (Zero)
        }

        Method (SLT2, 0, Serialized)
        {
            If (CondRefOf (\_PR.CPU0.GEAR))
            {
                Store (One, \_PR.CPU0.GEAR)
                \PNOT ()
            }

            Return (Zero)
        }

        Method (SLT3, 0, Serialized)
        {
            If (CondRefOf (\_PR.CPU0.GEAR))
            {
                Store (0x02, \_PR.CPU0.GEAR)
                \PNOT ()
            }

            Return (Zero)
        }

        Method (GLTS, 0, Serialized)
        {
            Store (\_PR.CPU0.GEAR, Local0)
            ShiftLeft (Local0, One, Local0)
            Or (Local0, One, Local0)
            Return (Local0)
        }
    }

    Scope (\_SB.PCI0.SAT1)
    {
        Method (SLT1, 0, Serialized)
        {
            If (CondRefOf (\_PR.CPU0.GEAR))
            {
                Store (Zero, \_PR.CPU0.GEAR)
                \PNOT ()
            }

            Return (Zero)
        }

        Method (SLT2, 0, Serialized)
        {
            If (CondRefOf (\_PR.CPU0.GEAR))
            {
                Store (One, \_PR.CPU0.GEAR)
                \PNOT ()
            }

            Return (Zero)
        }

        Method (SLT3, 0, Serialized)
        {
            If (CondRefOf (\_PR.CPU0.GEAR))
            {
                Store (0x02, \_PR.CPU0.GEAR)
                \PNOT ()
            }

            Return (Zero)
        }

        Method (GLTS, 0, Serialized)
        {
            Store (\_PR.CPU0.GEAR, Local0)
            ShiftLeft (Local0, One, Local0)
            And (MPMF, One, Local1)
            Or (Local0, Local1, Local0)
            Return (Local0)
        }
    }
}

