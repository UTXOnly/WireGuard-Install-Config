#!/bin/bash
BRed='\033[1;31m'
BGreen='\033[1;32m'
NC='\033[0m' # No Color
sudo apt-get update -y


conf_file=/etc/wireguard/wg0.conf
if [ -f "$conf_file" ]; then
    echo "$conf_file exists"
else
	sudo apt install -y wireguard
    wait
fi


umask 077; wg genkey | tee privatekey | wg pubkey > publickey

private_key=$(< privatekey)
public_key=$(< publickey)

sudo wg set wg0 peer $public_key allowed-ips 10.0.0.1/32

sudo chown ${UID}:${GID} /etc/wireguard
sudo chmod 757 /etc/wireguard
sudo chown ${UID}:${GID} /etc/wireguard/wg0.conf
sudo chmod 700 /etc/wireguard/wg0.conf
sudo chmod 755 /etc/wireguard