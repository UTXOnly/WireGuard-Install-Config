#!/bin/bash
GID=1003
User_ID=1003
USERNAME=wireguard

sudo groupadd -g $GID -o $USERNAME && \
sudo useradd -m -u $User_ID -g $GID -o -d /home/$USERNAME -s /bin/bash $USERNAME && \
echo "$USERNAME    ALL=(ALL:ALL) NOPASSWD: ALL"| sudo tee -a /etc/sudoers

sed '/net.ipv4.ip_forward=1/s/^#//' -i /etc/sysctl.conf
sysctl -p