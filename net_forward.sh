#!/bin/bash

sed '/net.ipv4.ip_forward=1/s/^#//' -i /etc/sysctl.conf
sysctl -p