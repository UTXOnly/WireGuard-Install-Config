#!/bin/bash

GID=1003
User_ID=1003
USERNAME=wireguard
BRed='\033[1;31m'
NC='\033[0m' # No Color

sudo groupadd -g $GID -o $USERNAME && \
sudo useradd -m -u $User_ID -g $GID -o -d /home/$USERNAME -s /bin/bash $USERNAME && \
echo "$USERNAME    ALL=(ALL:ALL) NOPASSWD: ALL"| sudo tee -a /etc/sudoers

#Enable IPv4 forwarding load new settings
sudo sed '/net.ipv4.ip_forward=1/s/^#//' -i /etc/sysctl.conf
sudo sysctl -p

sudo apt-get update -y

conf_file=/etc/wireguard/wg0.conf
if [ -f "$conf_file" ]; then
    echo "$conf_file exists"
else
	sudo apt install -y wireguard
    sudo touch /etc/wireguard/wg0.conf 
fi

sudo chown 1003:1003 /etc/wireguard
sudo chmod 757 /etc/wireguard

cd /etc/wireguard/

#Generate public/private keypair 
umask 077; wg genkey | tee privatekey | wg pubkey > publickey


#Create variable for private key
private_key=$(< privatekey)

#Populate wg0.conf w/ config and firewall rules to masquerade client traffic from server
sudo chmod 777 /etc/wireguard/wg0.conf
conf_file=/etc/wireguard/wg0.conf
sudo tee -a >${conf_file} <<EOF
[Interface]
PrivateKey = a_private_key
Address = 10.0.0.0/24
ListenPort = 51820
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
[Peer]
AllowedIPS = 10.0.0.0/24
PersistentKeepalive = 25
EOF

#Sed script to replace string w/ variable
sudo sed "s|a_private_key|$private_key|g" -i /etc/wireguard/wg0.conf

sudo chmod 755 /etc/wireguard/wg0.conf
sudo chown 1003:1003 /etc/wireguard/wg0.conf

#Quick enable wg0 interface
echo -e "${BRed}Do you want to bring up the WireGuard tunnel? (yes/no)${NC}"
read ANSWER
if [ $ANSWER == "yes" ]; then
    wg-quick up wg0
    cat wg_logo.txt
else
	echo "Not starting Wireguard"
fi

sudo apt install ufw
#Adjust firewall to allow SSH and wireguardVPN traffic
echo -e "${BRed}Do you want to enable UFW firewall now? (yes/no)${NC}"
read ANSWER
if [ $ANSWER == "yes" ]; then
    ufw allow 22/tcp
    ufw allow 22/udp
    ufw allow 51820/udp
    ufw enable
else
	echo "Not starting UFW firewall"
fi

#Create variable for host's public IP
first_ip_address="$(curl -Ls ifconfig.me)"

echo -e "${BRed}Your public IP is: $first_ip_address please save this to run with the add_pub_key.sh script${NC}"