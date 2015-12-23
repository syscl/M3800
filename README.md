OS X on DELL M3800 and XPS15 (9530)
====================================

* [Change Log] (https://github.com/syscl/M3800/blob/M3800/README.md)

2015-12-23

- Added new Touchpad/Trackpad driver with zoom for M3800/XPS9530.
- Removed VoodooPS2Controller.kext to avoid function abnormally in some special case.
- Fixed typo in README.md.


2015-12-10

- Added support for 1920*1080p model. (Don't worry about the progress, detection will be automatical.)
- Refined scripts (Runing more smooth).
- Easier to read.
- Removed ACPIBacklight.kext in ~/M3800/CLOVER/Kexts/10.11
- Minor bugs fixed.
- Revised README.md.


2015-12-9

- Fixed iasl counld not find problem
- Add auto update function


2015-12-7 

- Merge two scripts into one : easier to use than before.
- Add permission for two kernel extensions to solve problem known as no audio after installation.
- Boost the speed of the script.
- Update VoodooPS2Controller.kext to 11-28.
- Update CodecCommander.kext to 11-22.
- Use BrcmBluetoothInjector.kext in place of BrcmPatchRAM.kext to drive bluetooth in a more precise way.
- Remove ACPIBacklight.kext. 


2015-11-17 

- Add A10 bios file and flash tools (AFU)
- Bump version of Clover to v3320.
- Remove "Scan Entiries ..." to boost the progress of booting operation system.
- Config.plist updated
