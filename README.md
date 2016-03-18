OS X on DELL M3800 and XPS15 (9530)
====================================


This project targets at giving the relatively complete functional OS X for both Dell Precision M3800 and XPS15 9530. Before you start, there's a brief introduction of how to finish power up OS X on your laptop:

1. Create a vanilla installation disk(removable disk)
2. Install Clover with UEFI only and UEFI64Drivers to the installation disk just created 
3. Replace the origin Clover folder with the one under my Git/M3800/CLOVER
4. Patch bios to unlock bios menu
5. BIOS: set Advanced/CFG Lock = Disabled, System Agent (SA) Configuration/Graphics Configuration/Graphics Configuration/DVMT Pre-Allocated = 128MB, Advanced/SATA Operation = AHCI. To improve battery life, set Advanced(unlocked Menu)/CPU Configuration/LakeTiny Feature = Enabled.
6. Install OS X
7. Once you finish installation of OS X, you can do the following to finish the post installation of OS X:

How to use deploy.sh?
----------------

Download the latest version installation package/directory by entering the following command in a terminal window:

```sh
git clone https://github.com/syscl/M3800
```
This will download the whole installation directory to your current directory(./) and the next step is to change the permissions of the file (add +x) so that it can be run.


```sh
chmod +x ./M3800/deploy.sh
```


Run the script in a terminal windows by(Note: You should dump the ACPI tables by pressing F4/Fn+F4 under Clover first and then execute the following command lines):

```sh
cd M3800
./deploy.sh
```

Reboot your OS X to see the change. If you have sound problem, run the deploy.sh again to update the HDA.


Change Log
----------------

2016-3-18

- Fixed issue that external devices ejected improperly upon resume from sleep credit syscl/lighting/Yating Zhou. (More details should be found [here] (https://github.com/syscl/Fix-usb-sleep). 

2016-3-13

- Added magic number "01470c02" as PMheart/neycwcy10's suggestion to try to fix the issue #10.
- Refined configdata from dump codec from linux.
- Enable BT4LE-Handoff-Hotspot by kextstopatch.

2016-3-11

- Finally, M3800/XPS15(9530) can use ig-platform-id 0x0a2e0008(OS Version >= 10.10.2) with the lid wake function after sleep(credit syscl/lighting/Yating Zhou).
- Huge style change! We don't have to reboot 2x due to the change of ig-platform-id! Once you update your OS X(do not reboot), and run the deploy.sh again, then, you can enjoy every functions of OS X you want.
- If you have sound card problem, run the deploy.sh again and reboot to see if it can fix the problem.
- Removed FakePCIID_Intel_HDMI_Audio.kext since we have a better way to power up the HDMI audio.

2016-3-6

- Added 4K(3840 x 2160) support for M3800 credit SimplyLab(see issue #6).
- Changed config.plist/Graphics/Inject/Intel = false to fix installation stucks at booting stage.(Wait for feedback).
- Changed config.plist/KernelAndKextPatches/KextsToPatch/AppleIntelFramebufferAzul for enabling port 0x05 DP to HDMI (87000000 - > 06000000). 

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

- Huge change in deploy.sh, added function method to make the script easy to read, and yes, the script is faster than ever.


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
