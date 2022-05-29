#!/bin/bash

#client_ip_address="$(curl -Ls ifconfig.me)"

apt-get update
apt-get install -y wireguard

sleep 2

read -p "Paste in your WireGuard server public key" WG_server_pubkey

sleep 1

read -p "What is the IP address of your WireGuard server?" server_ip

sleep 2

scp root@$server_ip:/etc/wireguard/wg0.conf /etc/wireguard/

sleep 2

cd /etc/wiregaurd 


umask 077; wg genkey | tee privatekey | wg pubkey > publickey

cat privatekey

#Create variable for private key
private_key=$(< privatekey)

# Create conf file
touch /etc/wiregaurd/wg-client.conf


# input priv key to server

load_config="[Interface]
PrivateKey = a_private_key
 Address=10.0.0.4

[Peer]
# Ubuntu Digital Ocean Server
 PublicKey=WG_server_pubkey
 Endpoint=server_ip:51820
 AllowedIPs = 0.0.0.0/0 # Forward all traffic to server
 "

#Populate begining of config file
 echo load_config >> /etc/wiregaurd/wg0-client.sh

#Sed script to replace string w/ variable
sed -i "s/a_private_key/$private_key/g" /etc/wireguard/wg0-client.conf

#Sed script to replace string w/ variable
sed -i "s/WG_server_pubkey/$WG_server_pubkey/g" etc/wireguard/wg0-client.conf

#Sed script to replace string w/ variable
sed -i "s/server_ip/$server_ip/g" etc/wireguard/wg0-client.conf

#Quick enable wg0 interface
wg-quick up wg0

# SSH into server to edit config file w/ sed script
#ssh -t root@$server_ip 'cd /etc/wireguard/wg0.conf;sed -i "s/new_client_private_key/$private_key/g" /etc/wireguard/wg0-client.conf;'

echo "Your traffic is now encrypted"



