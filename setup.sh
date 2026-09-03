#!/usr/bin/env bash
set -eu -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"

# Ensure script is run as root
if [ "${EUID}" -ne 0 ]; then
    echo "You must run this script as root!"
    exit 1
fi

# The user to create and the SSH public key
NEW_USER="user"
SSH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGhNW2T8Aj1MnjEpaNRqoMYm/jL10PI7igBx084GN0U5"

# Update and install packages
apt update
apt -y upgrade
apt -y install \
    apparmor \
    apt-listchanges \
    apt-transport-https \
    aptitude \
    btop \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    dnsutils \
    fail2ban \
    fd-find \
    fuse-overlayfs \
    fzf \
    git \
    gnupg \
    htop \
    iproute2 \
    iputils-ping \
    libclang-dev \
    libfuse2 \
    libnss-myhostname \
    lsd \
    ncdu \
    neovim \
    net-tools \
    netcat-openbsd \
    network-manager \
    nload \
    python3-dev \
    python3-pip \
    rclone \
    restic \
    ripgrep \
    rsync \
    shellcheck \
    shfmt \
    smem \
    sudo \
    tmux \
    ufw \
    unattended-upgrades \
    unzip \
    wireguard \
    zsh

# Back up files that are replaced below
BACKUP_DIR="/var/backups/server-setup/$(date +%Y%m%d-%H%M%S)"
mkdir -p "${BACKUP_DIR}"

# Configure Debian sources to use the new format (deb822)
if [ -f /etc/apt/sources.list ]; then
    cp -a /etc/apt/sources.list "${BACKUP_DIR}/"
fi
rsync -rv "${SCRIPT_DIR}/etc/apt/" /etc/apt/
rm -f /etc/apt/sources.list
apt-get update

# Add a new user with root privileges (the password prompt sets the sudo password)
HOME_DIR="/home/${NEW_USER}"
if ! id -u "${NEW_USER}" >/dev/null 2>&1; then
    adduser --gecos "" "${NEW_USER}"
fi
usermod -a -G sudo "${NEW_USER}"

# Group allowed to SSH in (matches AllowGroups in sshd_config)
groupadd -f ssh-users
usermod -a -G ssh-users "${NEW_USER}"

# Set up the new user's ~/.ssh directory and authorized_keys
mkdir -p "${HOME_DIR}/.ssh"
chmod 700 "${HOME_DIR}/.ssh"
touch "${HOME_DIR}/.ssh/authorized_keys"
if ! grep -qxF "${SSH_KEY}" "${HOME_DIR}/.ssh/authorized_keys"; then
    echo "${SSH_KEY}" >>"${HOME_DIR}/.ssh/authorized_keys"
fi
chmod 600 "${HOME_DIR}/.ssh/authorized_keys"
chown -R "${NEW_USER}:${NEW_USER}" "${HOME_DIR}/.ssh"

# Configure unattended upgrades
dpkg-reconfigure -plow unattended-upgrades

# Back up the current SSH configuration and host keys
cp -a /etc/ssh "${BACKUP_DIR}/ssh"

# Generate server SSH host key (ed25519); regenerating invalidates
# clients' known_hosts
read -r -p "Regenerate SSH host key? [Y/n] " reply || reply=""
case "${reply}" in
[nN]*) ;;
*)
    rm -f /etc/ssh/ssh_host_*key*
    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key </dev/null
    ;;
esac

# Configure SSH
cp "${SCRIPT_DIR}/etc/issue.net" /etc/issue.net
rsync -rv "${SCRIPT_DIR}/etc/ssh" /etc/
chmod 644 /etc/ssh/*_config
sshd -t
systemctl restart sshd.service

# Configure UFW
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw enable
