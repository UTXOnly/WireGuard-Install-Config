#!/bin/bash

#Enable IPv4 forwarding
sed '/net.ipv4.ip_forward=1/s/^#//' -i /etc/sysctl.conf
sysctl -p


#Create variable for host's public IP
first_ip_address="$(curl -Ls ifconfig.me)"

echo "Your public IP is: " $first_ip_address

sleep 3

apt-get update
apt-get install -y wireguard

sleep 2

cd /etc/wireguard/
touch /etc/wireguard/wg0.conf

#Generate public/private keypair 
umask 077; wg genkey | tee privatekey | wg pubkey > publickey

#systemctl enable wg-quick@wg0
#systemctl start wg-quick@wg0

#Create variable for private key
a_private_key=$(< privatekey)

#Populate wg0.conf w/ config and firewall rules to masquerade client traffic from server


load_config="
[Interface]
PrivateKey = a_private_key
Address = 10.0.0.1/24
ListenPort = 51820
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
[Peer]
AllowedIPS = 10.0.0.1/24
PersistentKeepalive = 25
"

#Populate begining of config file
echo "$load_config" >> /etc/wireguard/wg0.conf

#Sed script to replace string w/ variable
sed -i "s/a_private_key/$a_private_key/g" /etc/wireguard/wg0.conf

#Quick enable wg0 interface
wg-quick up wg0


#Read user input as variable
read -p "What is the public key of the client?" client_pub_key

#Pipe contents of variable to append wg0.conf
echo "PublicKey = $client_pub_key"  >> wg0.conf

#Adjust firewall to allow SSH and wireguardVPN traffic
ufw allow 22/tcp
ufw allow 51820/udp
ufw enable
