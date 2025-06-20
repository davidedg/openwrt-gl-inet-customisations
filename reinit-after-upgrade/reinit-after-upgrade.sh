#!/bin/sh

set -e

REINIT=false
PACKAGES="htop mc"

SSHTUNNELPROFILE="cloudserver"
SSHTUNNEL=false
opkg status sshtunnel|grep ^Status:|grep install >/dev/null || (
  REINIT=true
  SSHTUNNEL=true
  PACKAGES="$PACKAGES sshtunnel"
)

F2FS=false
opkg status kmod-fs-f2fs|grep ^Status:|grep install >/dev/null || (
  REINIT=true
  F2FS=true
  PACKAGES="$PACKAGES f2fs-tools kmod-fs-f2fs"
)

TRIGGERHAPPY=false
opkg status triggerhappy|grep ^Status:|grep install >/dev/null || (
  REINIT=true
  TRIGGERHAPPY=true
  PACKAGES="$PACKAGES kmod-usb-hid triggerhappy coreutils-od coreutils-paste"
)

SMSFORWARD=false
[ -f forward-original ] || (
  REINIT=true
  SMSFORWARD=true
)

$REINIT && (
  opkg update || exit
  opkg install $PACKAGES || exit
)

$SSHTUNNEL && (
  h=`grep -A6 "config server $SSHTUNNELPROFILE" /etc/config/sshtunnel | awk '/option hostname/ { print $3 }'`
  u=`grep -A6 "config server $SSHTUNNELPROFILE" /etc/config/sshtunnel | awk '/option user/ { print $3 }'`
  p=`grep -A6 "config server $SSHTUNNELPROFILE" /etc/config/sshtunnel | awk '/option port/ { print $3 }'`

  OLD=`grep -v "\[$h\]:$p" /root/.ssh/known_hosts`
  NEW=`grep "\[$h\]:$p" /etc/config/sshtunnel_known_hosts`
  echo "$OLD" >  /root/.ssh/known_hosts
  echo "$NEW" >> /root/.ssh/known_hosts
  service sshtunnel start
)

$F2FS && (
  block detect | uci import fstab || exit
  uci set fstab.@mount[-1].enabled='1' || exit
  uci commit fstab || exit
  service fstab boot
)

$SMSFORWARD && (
  wget -O /etc/forward.new "https://github.com/davidedg/gl-inet-customisations/raw/refs/heads/main/sms-actions/forward" || exit
  chmod +x /etc/forward.new || exit
  cp /etc/forward /etc/forward-original || exit
  mv -f /etc/forward.new /etc/forward
)

$TRIGGERHAPPY && (
  cp -f /etc/config/blink_triggerhappy.conf /etc/triggerhappy/triggers.d/
  service triggerhappy restart
)

touch /root/reinit_complete
