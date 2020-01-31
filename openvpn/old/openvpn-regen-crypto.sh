#!/bin/bash

# Check if user has root priveleges
if [ "$USER" != 'root' ]; then
	echo "You must run this script as root!"
	exit 1;
fi

# Set up the directories, links, and account
cd /etc/openvpn/easy-rsa && source ./vars
./clean-all

# Regenerate crypto
rm /etc/openvpn/dh*.pem
openssl dhparam 4096 > /etc/openvpn/dh4096.pem
openvpn --genkey --secret /etc/openvpn/easy-rsa/keys/ta.key

# Regenerate the certificates
cd /etc/openvpn/easy-rsa
./build-ca
./build-key-server server
