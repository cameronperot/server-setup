#!/bin/bash
set -e

# Check if user has root priveleges
if [ "$USER" != 'root' ]; then
	echo "You must run this script as root!"
	exit 1;
fi

# Install the OpenVPN server
apt-get update
apt-get install -y openvpn easy-rsa

# Set up the directories, links, and account
mkdir -p /etc/openvpn/easy-rsa/keys && cd /etc/openvpn/easy-rsa/
cp -rf /usr/share/easy-rsa/* /etc/openvpn/easy-rsa
ln -s openssl-1.0.0.cnf openssl.cnf
cd /etc/openvpn/easy-rsa && source ./vars
./clean-all

# Generate crypto
openssl dhparam 2048 > /etc/openvpn/dh2048.pem
openvpn --genkey --secret /etc/openvpn/easy-rsa/keys/ta.key

# Generate the certificates
cd /etc/openvpn/easy-rsa
./build-ca
./build-key-server server
echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf
sysctl -p

# Create the client config directory
mkdir /etc/openvpn/ccd
chown nobody:nogroup /etc/openvpn/ccd

# Copy over the server config file
cp $PWD/../server.conf /etc/openvpn/server.conf
