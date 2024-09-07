#!/usr/bin/env bash
set -eu -o pipefail

# ensure script is run as root
if [ "$USER" != "root" ]; then
    echo "You must run this script as root!"
    exit 1
fi

# install syncthing; based on https://apt.syncthing.net/
mkdir -p /etc/apt/keyrings
curl -L -o /etc/apt/keyrings/syncthing-archive-keyring.gpg https://syncthing.net/release-key.gpg
echo "deb [signed-by=/etc/apt/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable" | sudo tee /etc/apt/sources.list.d/syncthing.list
apt-get update
apt-get install syncthing
