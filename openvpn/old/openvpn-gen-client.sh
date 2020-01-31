#!/bin/bash
set -e

# Check if user has root priveleges
if [ "$USER" != 'root' ]; then
	echo "You must run this script as root!"
	exit 1;
fi

# Ask the user what to name the client
echo "What would you like the client name to be (e.g. client1)"
read newclient
echo "Client will create files with the name $newclient"

# Generate the client credentials
cd /etc/openvpn/easy-rsa && source ./vars && ./build-key-pass $newclient

# Compress the client credentials
tar -C /etc/openvpn/easy-rsa/keys -cvzf /etc/openvpn/$newclient.tgz {ca.crt,$newclient.crt,$newclient.key,ta.key}

# Create the ccd file
touch /etc/openvpn/ccd/$newclient
sudo chmod 644 /etc/openvpn/ccd/$newclient
