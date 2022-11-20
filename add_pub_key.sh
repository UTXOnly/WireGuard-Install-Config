#!/bin/bash

echo -e "Would you like to:\n \n 1) Add server public key and IP address to client configuration? \n OR \n 2) Add client public key to server configuration? \n Please enter 1 or 2 and press ENTER" 
read ANSWER1
if [ $ANSWER1 == 1 ] ; then
    read -p "Please enter server public key then press ENTER: " WG_server_pub_key
    echo ""
    read -p "Please enter server public IP then press ENTER: " WG_server_ip
    sed -i "s/server_ip/$WG_server_ip/g" /etc/wireguard/wg0.conf
    sed -i "s/WG_server_pubkey/$WG_server_pubkey/g" /etc/wireguard/wg0.conf
    echo "Added key and IP"
elif [ $ANSWER1 == 2 ] ; then
        read -p "Please enter client public key then press ENTER" WG_client_pub_key
        echo ""
        echo "PublicKey = $client_pub_key"  >> /etc/wireguard/wg0.conf
        echo "Added client pub key"
else
    echo "That was not a valid selection, please run script again"
fi