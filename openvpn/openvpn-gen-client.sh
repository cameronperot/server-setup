#!/usr/bin/env bash
set -eu -o pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd -P )"

# Check if user has root priveleges
if [ "$USER" != 'root' ]; then
    echo "You must run this script as root!"
    exit 1;
fi

# Ask the user what to name the client
echo "What would you like the client name to be (e.g. client1)"
read -r NEW_CLIENT
echo "Client will create files with the name $NEW_CLIENT"

# Generate the client credentials
cd /etc/openvpn/easy-rsa
./easyrsa gen-req "$NEW_CLIENT"
./easyrsa sign-req client "$NEW_CLIENT"

# Compress the client credentials
NEW_CLIENT_DIR="/etc/openvpn/client/$NEW_CLIENT"
mkdir "$NEW_CLIENT_DIR"
cp ./ta.key "$NEW_CLIENT_DIR/"
cp ./pki/ca.crt "$NEW_CLIENT_DIR/"
cp "./pki/issued/$NEW_CLIENT.crt" "$NEW_CLIENT_DIR/client.crt"
cp "./pki/private/$NEW_CLIENT.key" "$NEW_CLIENT_DIR/client.key"
cp /etc/openvpn/client/client.conf "$NEW_CLIENT_DIR/client.conf"
tar -C "$NEW_CLIENT_DIR" -cvzf "/etc/openvpn/client/$NEW_CLIENT.tgz" {ca.crt,client.conf,client.crt,client.key,ta.key}

# Create the ccd file
touch "/etc/openvpn/ccd/$NEW_CLIENT"
sudo chmod 644 "/etc/openvpn/ccd/$NEW_CLIENT"
