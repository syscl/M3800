macOS on DELL M3800 and XPS15 (9530)
====================================


This project targets at giving the relatively complete functional macOS for both Dell Precision M3800 and XPS15 9530. Before you start, there's a brief introduction of how to finish powering up macOS on your laptop:

1. Create a vanilla installation disk(removable disk).
2. Install Clover with UEFI only and UEFI64Drivers to the installation disk just created. 
3. Replace the origin Clover folder with the one under my Git/M3800/CLOVER.
4. Patch bios to unlock bios menu.
5. BIOS settings:
```sh
Advanced:
    CPU Configuration/CFG Lock = Disabled
    CPU Configuration/LakeTiny Feature = Enabled

    SATA Operation = AHCI 

Chipset:
    PCH-IO Configuration/XHCI Mode = Smart Auto

    System Agent (SA) Configuration/Graphics Configuration:
        Aperture Size = 512MB
        DVMT Pre-Allocated = 160MB
        DVMT Total Gfx Mem = MAX
NOTE: Once you modify your settings in BIOS(especially Graphics Configuration in SA), you have to remove previous ACPI tables first, redump ACPI tables by press Fn+F4/F4 under Clover, and run deploy.sh again to patch your ACPI tables again.
```
6. Install macOS.
7. Once you finish installation of OS X, you can do the following steps to finish the post installation of OS X.

How to use deploy.sh?
----------------

Download the latest version installation package/directory by entering the following command in a terminal window:

```sh
git clone https://github.com/syscl/M3800
```
This will download the whole installation directory to your current directory(./) and the next step is to change the permissions of the file (add +x) so that it can be run.


```sh
cd M3800
chmod +x ./deploy.sh
```


Run the script in a terminal windows by(Note: You should dump the ACPI tables by pressing F4/Fn+F4 under Clover first and then execute the following command lines):

```sh
./deploy.sh
```

Reboot your OS X to see the change. If you have any problem about the script, try to run deploy in DEBUG mode by 
```sh
./deploy.sh -d
```

Note:
- ```VoodooPS2Controller``` is recommended on macOS ```Sierra```(10.```12+```)
- ```AppleSmartTouchPad``` users(recommend on 10.```11-```): for two finger scrolling you need to change the speed of the Scrolling once to get it work and also have to enable them in Trackpad preferences. 

#### Changelog 
[Change logs](https://github.com/syscl/M3800/blob/M3800/Changelog.md) for detail improvements
