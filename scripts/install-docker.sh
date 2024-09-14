#!/usr/bin/env bash
set -eu -o pipefail

# ensure script is run as root
if [ "$USER" != "root" ]; then
    echo "You must run this script as root!"
    exit 1
fi

# install docker based on https://docs.docker.com/engine/install/debian/
# add Docker's official GPG key
apt update
apt install ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# add the repository to apt sources
echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
    tee /etc/apt/sources.list.d/docker.list >/dev/null

# install the docker packages
apt update
apt install \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# verify that it works
docker run hello-world
