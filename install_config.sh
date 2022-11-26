#!/bin/bash
USERNAME=wireguardsvc
BRed='\033[1;31m'
BGreen='\033[1;32m'
NC='\033[0m' # No Color

sudo useradd -r $USERNAME -s /usr/sbin/nologin
User_ID=$(id -u $USERNAME)
GID=$(id -g $USERNAME)

#Enable IPv4 forwarding load new settings
sudo sed '/net.ipv4.ip_forward=1/s/^#//' -i /etc/sysctl.conf
sudo sysctl -p

sudo apt-get update -y

conf_file=/etc/wireguard/wg0.conf
if [ -f "$conf_file" ]; then
    echo "$conf_file exists"
else
	sudo apt install -y wireguard
    wait
    sudo touch /etc/wireguard/wg0.conf 
fi

sudo chown ${User_ID}:${GID} /etc/wireguard
sudo chmod 777 /etc/wireguard

cd /etc/wireguard/

#Generate public/private keypair 
umask 077; wg genkey | tee privatekey | wg pubkey > publickey

#Create variable for private key
private_key=$(< privatekey)
public_key=$(< publickey)

#Populate wg0.conf w/ config and firewall rules to masquerade client traffic from server

conf_file=/etc/wireguard/wg0.conf
sudo chmod 777 /etc/wireguard/wg0.conf
tee -a >${conf_file} << EOF
[Interface]
PrivateKey = a_private_key
Address = 10.0.0.1/24
ListenPort = 51820
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
[Peer]
AllowedIPS = 10.0.0.4/24
PersistentKeepalive = 25
EOF

#Sed script to replace string w/ variable
sudo sed "s|a_private_key|$private_key|g" -i /etc/wireguard/wg0.conf

sudo chown ${User_ID}:${GID} /etc/wireguard/wg0.conf
sudo chmod 644 /etc/wireguard/wg0.conf
sudo chmod 755 /etc/wireguard

sudo apt install ufw
#Adjust firewall to allow SSH and wireguardVPN traffic
echo -e "${BGreen}Do you want to enable UFW firewall now?\n${BRed}WARNING this host will only be able accessable on Port 22 (SSH) or Port 8152/udp (Wireguard) \nIf you do not know what this means select NO and find out! \n (yes/no)${NC}"

read ANSWER
if [ $ANSWER == "yes" ]; then
    sudo ufw allow 22
    sudo ufw allow 51820/udp
    sudo ufw enable
else
    sudo ufw allow 22
    sudo ufw allow 51820/udp
	echo -e "${BRed}Not starting UFW firewall, to start firewall use the command: sudo ufw enable${NC}"
fi

echo -e "${BGreen}Install finished${NC}"
#Create variable for host's public IP
public_ip_address="$(curl -Ls ifconfig.me)"

echo -e "\n${BGreen}Your public IP is: ${BRed}$public_ip_address ${BGreen}please save this to run with the add_pub_key.sh script${NC}"
echo -e "${BGreen}Your Wireguard server public key is:\n${BRed}${public_key}\nYou will need to save this to run the add_pub_key.sh script${NC}"
