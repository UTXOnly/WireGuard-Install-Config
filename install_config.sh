#!/bin/bash



first_ip_address="$(curl -Ls ifconfig.me)"

echo "Your public IP is: " $first_ip_address

sleep 5

apt-get install wiregaurd -Y

cd /etc/wiregaurd

#umask 077; wg genkey | tee privatekey | wg pubkey > publickey


systemctl enable wg-quick@wg0

private_key=($

load_config="
[Interface]
PrivateKey = <private_key>
Address = 10.0.0.1/24
ListenPort = 51820
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE"

peer_addition
cat $load_config >> /etc/wireguard/wg0.conf

sed -i "s/private_key//g" /etc/wireguard/wg0.conf


read -p "What is the public key of the client?" client_pub_key

cat $client_pub_key | >> wg0.conf

ufw allow 22/tcp
ufw allow 51820/udp
ufw enable
