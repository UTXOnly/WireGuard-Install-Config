#!/bin/bash

USERNAME=wireguardsvc
BRed='\033[1;31m'
BGreen='\033[1;32m'
NC='\033[0m' # No Color

sudo useradd -r $USERNAME -s /usr/sbin/nologin
User_ID=$(id -u $USERNAME)
GID=$(id -g $USERNAME)

sudo apt-get update -y
sudo apt install resolvconf -y

#If file does not exisit, create it
conf_file=/etc/wireguard/wg0.conf
if [ -f "$conf_file" ]; then
    echo "$conf_file exists"
else
	sudo apt install -y wireguard
    wait
    sudo touch /etc/wireguard/wg0.conf
fi
sudo chown ${User_ID}:${GID} /etc/wireguard
sudo chmod 757 /etc/wireguard
cd /etc/wireguard 

umask 077; wg genkey | tee privatekey | wg pubkey > publickey

#Create variable for private key
private_key=$(< privatekey)
public_key=$(< publickey)
sudo chmod 777 /etc/wireguard/wg0.conf
# populate wg0.conf file
tee >${conf_file} << EOF
[Interface]
PrivateKey = a_private_key
Address=10.0.0.4

[Peer]
PublicKey=WG_server_pubkey
Endpoint=server_ip:51820
AllowedIPs = 0.0.0.0/0 # Forward all traffic to server

EOF

#Sed script to replace string w/ variable
sudo sed "s|a_private_key|$private_key|g" -i /etc/wireguard/wg0.conf

sudo chown ${User_ID}:${GID} /etc/wireguard/wg0.conf
sudo chmod 644 /etc/wireguard/wg0.conf
sudo chmod 755 /etc/wireguard

echo -e "${BGreen}Install finished${NC}"
echo -e "${BGreen} Your Wireguard client public key is:\n${BRed}${public_key} \n You will need to save this to run the add_pub_key.sh script${NC}"
