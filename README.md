OS X on DELL M3800 and XPS15 (9530)
====================================

* [Change Log] (https://github.com/syscl/M3800/blob/M3800/README.md)

2015-12-25

- Huge change in Deploy.sh, added function method to make the script easy to read, and yes, the script is faster than ever.


2015-12-24

- Fixed typo that will cause AUDIO do not work properly.
- Added new installation guide and clean operation for model of 1920 x 1080p.
- Updated new bluetooth drivers to solve failure of searching bluetooth devices in some cases for all platforms of OS X. 


2015-12-23

- Added new Touchpad/Trackpad driver with zoom for M3800/XPS9530.
- Removed VoodooPS2Controller.kext to avoid function abnormally in some special cases.
- Fixed typo in README.md.
- Updated sytle of README.md.


2015-12-10

- Added support for 1920*1080p model. (Don't worry about the progress, detection will be automatical.)
- Refined scripts (Runing more smooth).
- Easier to read.
- Removed ACPIBacklight.kext in ~/M3800/CLOVER/Kexts/10.11
- Fixed minor bugs.
- Revised README.md.


2015-12-9

- Fixed iasl counld not find problem.
- Added auto update function.


2015-12-7 

- Merged two scripts into one : easier to use than before.
- Added permission for two kernel extensions to solve problem known as no audio after installation.
- Boosted the speed of the script.
- Updated VoodooPS2Controller.kext to 11-28.
- Updated CodecCommander.kext to 11-22.
- Used BrcmBluetoothInjector.kext in place of BrcmPatchRAM.kext to drive bluetooth in a more precise way.
- Removed ACPIBacklight.kext. 


2015-11-17 

- Added A10 bios file and flash tools (AFU).
- Bumped version of Clover to v3320.
- Removed "Scan Entiries ..." to boost the progress of booting operation system.
- Updated Config.plist
