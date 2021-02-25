### SwitchSDSetup v.2

### Only use if you know what youre doing, not updated in a few months, may or may not work

Install 7zip, python and python-usb before running the script.

Tested on Ubuntu, may or may not work on other distros, may or may not work on VM.

Start script with '**sudo /path/to/script/setup.sh**' and navigate through the menus, it should be more or less self explanatory.
Once you configured everything, select "Save changes", this will write everything to the selected device.

If you want to install to internal storage (eMMC), select "eMMC RAW GPP" in Hekate and connect the switch via USB, then start the script (or refresh device list).
***MAKE SURE TO HAVE A FULL BACKUP OF EMMC*** It will be fully wiped.
The script will detect if the selected device is eMMC, some options may be not available (e.g. EmuMMC). 

If there are existing partitions on the selected storage device, you can reuse them and dont format.


The script supports installing l4t ubuntu, android oreo, up to 2 EmuMMCs, up to 2 Android installations (Android Oreo + Android Q, Android Q + Android Q).

To install Android Q, place tegra210-icosa.dtb and lineage-17.1-[date]-UNOFFICIAL-[model].zip or tegra210-icosa.dtb and system.img, vendor.img, boot.img in a directory and start the script from that directory (or, if you dont start the script from there, navigate to that directory on image selection)


As always, im not responsible, if your switch ends up as paperweight, you overwrite your eMMC and dont have a backup or your house burns down.
