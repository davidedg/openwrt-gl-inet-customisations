TriggerHappy on OpenWRT
=======================

Fire [one instance](./singleinstance.sh) of a script upon receiving a combination of key/mouse events.

\
Install USB HID modules:

    opkg install kmod-usb-hid

Plug your device and make sure files inside /dev/input/ are created.

Install Trigger Happy

    opkg install triggerhappy

Verify your combinations with:

    thd --dump /dev/input/event*

Configure /etc/triggerhappy/triggers.d/triggers.conf, e.g.:

    BTN_RIGHT+BTN_LEFT      1       /etc/config/singleinstance.sh -l -t blink -x 60 -s /mnt/sda1/blink/chroot-blink-arm.sh
    BTN_LEFT+BTN_RIGHT      1       /etc/config/singleinstance.sh -l -t blink -x 60 -s /mnt/sda1/blink/chroot-blink-arm.sh
    BTN_RIGHT+BTN_LEFT      0       /etc/config/singleinstance.sh -l -t blink -x 60 -s /mnt/sda1/blink/chroot-blink-arm.sh
    BTN_LEFT+BTN_RIGHT      0       /etc/config/singleinstance.sh -l -t blink -x 60 -s /mnt/sda1/blink/chroot-blink-arm.sh


If using the AWS Lambda version:

    BTN_LEFT       1       /etc/config/singleinstance.sh -l -t blink -x 60 -s /etc/config/blink-awslambda.sh arm
    BTN_RIGHT      1       /etc/config/singleinstance.sh -l -t blink -x 60 -s /etc/config/blink-awslambda.sh disarm


Notes:

If you are testing this on a VMWare Workstation VM, you might need:

    usb.generic.allowHID = "TRUE"
