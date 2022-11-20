#!/bin/bash

$1=WG_server_pub_key
$2=server_ip
GID=1003
UID=1003
USERNAME=wireguard

groupadd -g $GID -o $USERNAME && \
useradd -m -u $UID -g $GID -o -d /home/$USERNAME -s /bin/bash $USERNAME && \
echo "$USERNAME    ALL=(ALL:ALL) NOPASSWD: /usr/bin/append-to-hosts" | tee -a /etc/sudoers
#client_ip_address="$(curl -Ls ifconfig.me)"
apt-get update
conf_file=/etc/wireguard/wg0.conf
if [ -f "$conf_file" ]; then
    echo "$FILE exists"
    
else
	apt-get install -y wireguard
fi

echo "You will need to upload your public key to your wireguard server"

echo "You will also need to "


#If file does not exisit, create it
conf_file=/etc/wireguard/wg0.conf
if [ -f "$conf_file" ]; then
    echo "$conf_file exists"
else
	touch /etc/wireguard/wg0.conf_file
    apt-get install -y wireguard
    chown wireguard:1003 /etc/wireguard/wg0.conf
fi

cd /etc/wireguard 


umask 077; wg genkey | tee privatekey | wg pubkey > publickey


#Create variable for private key
private_key=$(< privatekey)

# Create conf file
touch /etc/wireguard/wg0.conf


# input priv key to server
conf_file=/etc/wireguard/wg0.conf

tee >${conf_file} << EOF
[Interface]
PrivateKey = a_private_key
Address=10.0.0.4

[Peer]
PublicKey=WG_server_pubkey
Endpoint=server_ip:51820
AllowedIPs = 0.0.0.0/0 # Forward all traffic to server
EOF
#Populate begining of config file
#echo load_config >> /etc/wireguard/wg0.conf

#Sed script to replace string w/ variable
sed -i "s/a_private_key/$private_key/g" /etc/wireguard/wg0.conf

#Sed script to replace string w/ variable
sed -i "s/WG_server_pubkey/$WG_server_pubkey/g" /etc/wireguard/wg0.conf

#Sed script to replace string w/ variable
sed -i "s/server_ip/$server_ip/g" /etc/wireguard/wg0.conf

#Quick enable wg0 interface

read -p "Do you want to bring up the WireGuard tunnel?"
wg-quick up wg0



echo "Your traffic is now encrypted"
echo "
 __          ___                                    _   _    _ _____  _ 
 \ \        / (_)                                  | | | |  | |  __ \| |
  \ \  /\  / / _ _ __ ___  __ _ _   _  __ _ _ __ __| | | |  | | |__) | |
   \ \/  \/ / | | '__/ _ \/ _` | | | |/ _` | '__/ _` | | |  | |  ___/| |
    \  /\  /  | | | |  __/ (_| | |_| | (_| | | | (_| | | |__| | |    |_|
     \/  \/   |_|_|  \___|\__, |\__,_|\__,_|_|  \__,_|  \____/|_|    (_)
                           __/ |                                        
                          |___/                                         
"



