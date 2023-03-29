#!/bin/bash

set -e
#set -x

echo "==> Restore apt repository source."
curl https://raw.githubusercontent.com/Ubyon/trustgate-scripts/main/ubuntu20/apt.tgz -o /tmp/apt.tgz 
mv /etc/apt /etc/apt-old
mkdir /etc/apt
tar xvf /tmp/apt.tgz -C /etc/apt/
apt-get update -y

echo "==> Remove sss from nsswitch.conf"
mv /etc/nsswitch.conf /etc/nsswitch.conf.old
curl \
  https://raw.githubusercontent.com/Ubyon/trustgate-scripts/main/ubuntu20/nsswitch.conf | \
  tee /etc/nsswitch.conf > /dev/null

echo "==> Disable unused daemons."
for xx in cron autofs sendmail sssd; do systemctl stop $xx; systemctl disable $xx; done

echo
echo "==> VM is ready for ubos installation."
