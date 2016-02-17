OS X on DELL M3800 and XPS15 (9530)
====================================

* [Change Log] (https://github.com/syscl/M3800/blob/M3800/README.md)

2016-2-17

- Improved the configuration of ApplePS2SmartTouchPad.kext/Contents/config.plist and ApplePS2SmartTouchPad.kext/Contents/PlugIns/ApplePS2Keyboard.kext/Contents/config.plist:
- Set FinerFnBrightnessControl = NO and FinerFnVolumeControl = NO such that Keyboard performs/mute brightness and volume as OS X.
- 3 finger swipe up = Open Mission Control.
- 3 finger swipe down = Open Launchpad.
- 3 finger swipe left = Switch Previous Application.
- 3 finger swipe right = Switch Next Application. 
- 4 finger swipe up = Hide all Windows/Applications.
- 4 finger swipe down = Hide current Window/Application.
- 4 finger swipe left = Back.
- 4 finger swipe right = Go.
- 4 finger pinch = Open Mission Control.
- 5 finger pinch = Open Dashboard.
- My next step is going to find more details of touchpad of M3800/XPS9530 under Linux to make the ApplePS2SmartTouchPad.kext more comfortable to use than ever. (Coming soon!)
- Another problem is that after a full sleep, I can't reproduce the fix I made to fix the HP lose sound problem after a cold boot, really boring since I usually plug in HP all the time. I'm finding new way to fix this annoying problem. (After extensive explore, I believe this bug is produced by AppleHDA, since there's no such problem under Windows and Linux. Actually, Linux has this bug, but it can be fixed through a re-plugged-in HP.)


2016-2-12

- Solve the injected headphone will lose sound problem after a cold boot. (syscl)
- Sync vbourachot's repo to fix the headphone distortion (credit vbourachot)


2016-2-5

- Improve the compatibility of the executive script: This change / improvement allows the script to patch the OS X again while the patches of Dell Precision M3800 (3200 x 1800) will fail due to Graphics kexts fail to load.


2016-2-4

- Fixed a major problem that cause the ACPI tables patch fail.
- Use UUID to locate the EFI partition instead of IDENTIFER that may change after reboot.

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
- Updated style of README.md.


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
