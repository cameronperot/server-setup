#!/usr/bin/env bash
set -eu -o pipefail

# ensure script is run as root
if [ "$USER" != "root" ]; then
    echo "You must run this script as root!"
    exit 1
fi

# install podman
apt-get update
apt-get -y install \
    containers-storage \
    dbus-user-session \
    fuse-overlayfs \
    podman \
    slirp4netns \
    uidmap
