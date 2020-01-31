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
cd /etc/openvpn/easy-rsa && ./easyrsa gen-req $newclient && ./easyrsa sign-req client $newclient

# Compress the client credentials
newclient_dir=/etc/openvpn/client/$newclient
mkdir $newclient_dir
cp ./ta.key $newclient_dir/
cp ./pki/ca.crt $newclient_dir/
cp ./pki/issued/$newclient.crt $newclient_dir/client.crt
cp ./pki/private/$newclient.key $newclient_dir/client.key
cp /etc/openvpn/client/client.conf $newclient_dir/client.conf
tar -C $newclient_dir -cvzf /etc/openvpn/client/$newclient.tgz {ca.crt,client.conf,client.crt,client.key,ta.key}

# Create the ccd file
touch /etc/openvpn/ccd/$newclient
sudo chmod 644 /etc/openvpn/ccd/$newclient
