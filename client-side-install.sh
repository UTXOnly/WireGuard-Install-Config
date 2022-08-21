#!/bin/bash

#client_ip_address="$(curl -Ls ifconfig.me)"
apt-get update
conf_file=/etc/wireguard/wg0.conf
if [ -f "$conf_file" ]; then
    echo "$FILE exists"
    
else
	apt-get install -y wireguard
fi

#apt-get install -y wireguard



read -p "Paste in your WireGuard server public key  :" WG_server_pubkey



read -p "What is the IP address of your WireGuard server?  :" server_ip


#If file does not exisit, create it
conf_file=/etc/wireguard/wg0.conf
if [ -f "$conf_file" ]; then
    echo "$FILE exists."
else
	touch /etc/wireguard/wg0.conf_file
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
echo load_config >> /etc/wireguard/wg0.conf

#Sed script to replace string w/ variable
sed -i "s/a_private_key/$private_key/g" /etc/wireguard/wg0.conf

#Sed script to replace string w/ variable
sed -i "s/WG_server_pubkey/$WG_server_pubkey/g" /etc/wireguard/wg0.conf

#Sed script to replace string w/ variable
sed -i "s/server_ip/$server_ip/g" /etc/wireguard/wg0.conf

#Quick enable wg0 interface
wg-quick up wg0

# SSH into server to edit config file w/ sed script
#ssh -t root@$server_ip 'cd /etc/wireguard/wg0.conf;sed -i "s/new_client_private_key/$private_key/g" /etc/wireguard/wg0-client.conf;'

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



