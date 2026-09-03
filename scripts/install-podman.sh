#!/usr/bin/env bash
set -eu -o pipefail

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "You must run this script as root!" >&2
    exit 1
fi

# Install Podman and modern rootless/runtime stack
apt update
apt install -y \
    crun \
    dbus-user-session \
    fuse-overlayfs \
    passt \
    podman \
    uidmap

echo "Podman installed successfully!"
