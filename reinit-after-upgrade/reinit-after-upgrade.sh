#!/bin/sh

REINIT=false
PACKAGES=""
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

$REINIT && (
  opkg update || exit
  opkg install $PACKAGES
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

touch /root/reinit_complete
