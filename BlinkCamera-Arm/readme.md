Blink Cameras arming via script
===============================

Based on the amazing [blinkpy](https://pypi.org/project/blinkpy/) library.

Unfortunately, XE300 currently has OpenWRT 22.x with Python 3.7 and older modules which cannot work with blinkpy.

Additionally, python-light + required modules would take up ~40MB of storage.

I tried backporting Python 3.9 and newer modules from OpenWrt 24.10, but failed after struggling 2 days on it.

Instead, I realised this modem has an external SD slot!

Long story short:

- [Format and auto-mount](https://openwrt.org/docs/guide-user/storage/usb-drives) an SD card as F2FS.
- Export a recent mips docker image from OpenWRT 24.10 ( e.g. openwrt/rootfs:mips_24kc-openwrt-24.10 )
- Import the image and expand it to the SD card
- chroot into the image and enjoy the new python version!


More detailed notes
-------------------

On an Ubuntu machine (it does not need to be run on OpenWRT):

    docker pull --platform linux/mips_24kc  openwrt/rootfs:mips_24kc-openwrt-24.10
    docker run --entrypoint /bin/true --name owrt openwrt/rootfs:mips_24kc-openwrt-24.10
    docker export owrt > owrt.tar

The second command will give an error you can ignore.

Transfer the owrt.tar to the SD card (e.g. /mnt/sda1)

Expand the rootfs:

    mkdir /mnt/sda1/owrt
    cd /mnt/sda1/owrt && tar xf ../owrt.tar

Create required directory for opkg
    
    mkdir /mnt/sda1/owrt/var/lock

Change root with:

    chroot /mnt/sda1/owrt /bin/sh

Inside the chroot, update and install required packages:

    opkg update --no-check-certificate
    opkg install ca-certificates --no-check-certificate
    opkg install python3-dateutil python3-requests python3-slugify python3-sortedcontainers python3-aiohttp --no-check-certificate
    opkg install python3-pip --no-check-certificate
    pip install aiofiles
    pip install blinkpy
    pip list


Now the blinkpy library can be used, e.g.:

    chroot /mnt/sda1/owrt /usr/bin/python /blink-arm.py


With the [blink-arm.py](./blink-arm.py) script inside the chroot (/mnt/sda1/owrt/blink-arm.py)

I use this to automate arming the system from a remote controller that can work with [TriggerHappy](../triggerhappy-scripts/triggerhappy.md):
