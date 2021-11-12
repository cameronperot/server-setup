#!/usr/bin/env bash
set -eu -o pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd -P )"

# Check if user has root priveleges
if [ "$USER" != 'root' ]; then
    echo "You must run this script as root!"
    exit 1;
fi

# Install the OpenVPN server
apt-get update
apt-get install -y \
    openvpn \
    easy-rsa

# Set up the directories, links, and account
mkdir -p /etc/openvpn/easy-rsa/keys
cd /etc/openvpn/easy-rsa/
cp -rf /usr/share/easy-rsa/* /etc/openvpn/easy-rsa
ln -s openssl-1.0.0.cnf openssl.cnf

# Generate the certificates
cd /etc/openvpn/easy-rsa
./easyrsa init-pki
./easyrsa build-ca nopass
./easyrsa gen-req server nopass
./easyrsa sign-req server server
./easyrsa gen-dh
openvpn --genkey --secret ta.key
cp ta.key /etc/openvpn/
cp pki/ca.crt /etc/openvpn/
cp pki/private/server.key /etc/openvpn/
cp pki/issued/server.crt /etc/openvpn/
cp pki/dh.pem /etc/openvpn/

echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf
sysctl -p

# Create the client config directory
mkdir /etc/openvpn/ccd
chown nobody:nogroup /etc/openvpn/ccd

# Copy over the server config file
cp $DIR/server.conf /etc/openvpn/server.conf
mkdir -p /etc/openvpn/client
cp $DIR/client.conf /etc/openvpn/client/client.conf
