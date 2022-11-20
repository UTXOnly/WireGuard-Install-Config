#!/bin/bash

#client_pub_key=$1

GID=1003
User_ID=1003
USERNAME=wireguard

groupadd -g $GID -o $USERNAME && \
useradd -m -u $User_ID -g $GID -o -d /home/$USERNAME -s /bin/bash $USERNAME && \
echo "$USERNAME    ALL=(ALL:ALL) NOPASSWD: ALL"| tee -a /etc/sudoers

#Enable IPv4 forwarding
#sed '/net.ipv4.ip_forward=1/s/^#//' -i /etc/sysctl.conf
#sysctl -p


#Create variable for host's public IP
first_ip_address="$(curl -Ls ifconfig.me)"

echo "Your public IP is: " $first_ip_address

#su - wireguard
apt-get update -y

conf_file=/etc/wireguard/wg0.conf
if [ -f "$conf_file" ]; then
    echo "$conf_file exists"
else
	apt install -y wireguard
    touch /etc/wireguard/wg0.conf
    
    
fi
chown 1003:1003 /etc/wireguard
chmod 666 /etc/wireguard
cd /etc/wireguard/
#su - wireguard -c "touch /etc/wireguard/wg0.conf"
chmod 777 /etc/wireguard/wg0.conf
chown 1003:1003 /etc/wireguard/wg0.conf


#Generate public/private keypair 
umask 077; wg genkey | tee privatekey | wg pubkey > publickey


#Create variable for private key
private_key=$(< privatekey)

#Populate wg0.conf w/ config and firewall rules to masquerade client traffic from server
conf_file=/etc/wireguard/wg0.conf
tee -a >${conf_file} <<EOF
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
su - wireguard -c 'sed "s|a_private_key|$private_key|g" -i /etc/wireguard/wg0.conf'


#Read user input as variable
#read -p "What is the public key of the client?" client_pub_key

#Pipe contents of variable to append wg0.conf
#echo "PublicKey = $client_pub_key"  >> wg0.conf

#Quick enable wg0 interface
read -p "Do you want to bring up the WireGuard tunnel? (yes/no)" ANSWER
if [ $ANSWER == "yes" ]; then
    wg-quick up wg0
    cat wg_logo.txt
else
	echo "Not starting Wireguard"
fi

apt install ufw
#Adjust firewall to allow SSH and wireguardVPN traffic

read -p "Do you want to enable UFW firewall now? (yes/no)" ANSWER
if [ $ANSWER == "yes" ]; then
    ufw allow 22/tcp
    ufw allow 22/udp
    ufw allow 51820/udp
    ufw enable
else
	echo "Not starting UFW firewall"
fi