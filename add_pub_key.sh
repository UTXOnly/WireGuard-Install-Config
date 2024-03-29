#!/bin/bash

BRed='\033[1;31m'
BGreen='\033[1;32m'
NC='\033[0m' # No Color

echo -e "\nWould you like to:\n \n${BGreen} 1) Add server public key and IP address to client configuration?${NC} \n \n OR \n \n${BGreen}2) Add client public key to server configuration?${NC} \n \n Please enter 1 or 2 and press ENTER \n" 
read ANSWER1
if [ $ANSWER1 == 1 ] ; then
    echo -e "\nPlease enter server public key then press ENTER: " 
    read WG_server_pub_key
    echo ""
    read -p "Please enter server public IP then press ENTER: " WG_server_ip
    sudo sed "s|server_ip|$WG_server_ip|g" -i /etc/wireguard/wg0.conf
    sudo sed "s|WG_server_pubkey|$WG_server_pub_key|g" -i /etc/wireguard/wg0.conf
    echo -e "${BGreen}Added key and IP${NC}"
elif [ $ANSWER1 == 2 ] ; then
    echo -e "\nPlease enter client public key then press ENTER\n"
    read WG_client_pub_key
    echo ""
    echo "PublicKey = $WG_client_pub_key" | sudo tee -a /etc/wireguard/wg0.conf
    echo -e "${BGreen}Added client pub key${NC}"
else
    echo "That was not a valid selection, please run script again"
fi