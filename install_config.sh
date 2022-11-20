#!/bin/bash

client_pub_key=$1
#$2=server_ip
GID=1003
UID=1003
USERNAME=wireguard

groupadd -g $GID -o $USERNAME && \
useradd -m -u $UID -g $GID -o -d /home/$USERNAME -s /bin/bash $USERNAME && \
echo "$USERNAME    ALL=(ALL:ALL) NOPASSWD: ALL"| tee -a /etc/sudoers


#Enable IPv4 forwarding
sed '/net.ipv4.ip_forward=1/s/^#//' -i /etc/sysctl.conf
sysctl -p


#Create variable for host's public IP
first_ip_address="$(curl -Ls ifconfig.me)"

echo "Your public IP is: " $first_ip_address

#su - wireguard
apt-get update -y

conf_file=/etc/wireguard/wg0.conf
if [ -f "$conf_file" ]; then
    echo "$conf_file exists"
else
	touch /etc/wireguard/wg0.conf_file
    apt-get install -y wireguard
    chown wireguard:1003 /etc/wireguard/wg0.conf
fi

chown wireguard:1003 /etc/wireguard
cd /etc/wireguard/
touch /etc/wireguard/wg0.conf
chmod 777 /etc/wireguard/wg0.conf

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
AllowedIPS = 10.0.0.1/24
PersistentKeepalive = 25
EOF


#Sed script to replace string w/ variable
sed -i "s/a_private_key/$private_key/g" /etc/wireguard/wg0.conf


#Read user input as variable
#read -p "What is the public key of the client?" client_pub_key

#Pipe contents of variable to append wg0.conf
echo "PublicKey = $client_pub_key"  >> wg0.conf

#Quick enable wg0 interface
read -p "Do you want to bring up the WireGuard tunnel? (yes/no)" ANSWER
if [ $ANSWER == "yes" ]; then
    wg-quick up wg0
else
	#\break
fi

sudo apt install ufw
#Adjust firewall to allow SSH and wireguardVPN traffic

read -p "Do you want to enable UFW firewall now? (yes/no)" ANSWER
if [ $ANSWER == "yes" ]; then
    ufw allow 22/tcp
    ufw allow 22/udp
    ufw allow 51820/udp
    ufw enable
else
	#break
fi


echo '
 __          ___                                    _   _    _ _____  _ 
 \ \        / (_)                                  | | | |  | |  __ \| |
  \ \  /\  / / _ _ __ ___  __ _ _   _  __ _ _ __ __| | | |  | | |__) | |
   \ \/  \/ / | | '__/ _ \/ _` | | | |/ _` | '__/ _` | | |  | |  ___/| |
    \  /\  /  | | | |  __/ (_| | |_| | (_| | | | (_| | | |__| | |    |_|
     \/  \/   |_|_|  \___|\__, |\__,_|\__,_|_|  \__,_|  \____/|_|    (_)
                           __/ |                                        
                          |___/                                         
'
