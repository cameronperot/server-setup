#!/usr/bin/env bash
set -eu -o pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"

# ensure script is run as root
if [ "$USER" != "root" ]; then
    echo "You must run this script as root!"
    exit 1
fi

# update and install packages
apt update
apt -y upgrade
apt -y install \
    apparmor \
    apt-listchanges \
    aptitude \
    btop \
    build-essential \
    ca-certificates \
    curl \
    fail2ban \
    fd-find \
    fuse-overlayfs \
    git \
    gnupg \
    htop \
    lsd \
    ncdu \
    net-tools \
    nload \
    python3-dev \
    python3-pip \
    ripgrep \
    rsync \
    shellcheck \
    shfmt \
    smem \
    sudo \
    tmux \
    ufw \
    unattended-upgrades \
    vim \
    wireguard \
    zsh

# add a new user with root privileges
NEW_USER="user"
SSH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGhNW2T8Aj1MnjEpaNRqoMYm/jL10PI7igBx084GN0U5"
HOME_DIR="/home/$NEW_USER"
adduser --gecos "" "$NEW_USER"
/usr/sbin/usermod -a -G sudo "$NEW_USER"

# set up the new user's ~/.ssh directory and authorized_keys
mkdir "$HOME_DIR/.ssh"
chmod 700 "$HOME_DIR/.ssh"
echo "$SSH_KEY" >>"$HOME_DIR/.ssh/authorized_keys"
chmod 600 "$HOME_DIR/.ssh/authorized_keys"
chown -R "$NEW_USER:$NEW_USER" "$HOME_DIR/.ssh"

# configure unattended upgrades
dpkg-reconfigure -plow unattended-upgrades

# generate server SSH keys (ed25519 and 4096-bit RSA)
cd /etc/ssh
rm ssh_host_*key*
ssh-keygen -t ed25519 -f ssh_host_ed25519_key </dev/null
ssh-keygen -t rsa -b 4096 -f ssh_host_rsa_key </dev/null

# edit the moduli file to remove small primes
awk '$5 > 3071' /etc/ssh/moduli >"${HOME}/moduli"
wc -l "${HOME}/moduli"
mv "${HOME}/moduli" /etc/ssh/moduli

# configure ssh
cp "$DIR"/etc/issue.net /etc/issue.net
cp "$DIR"/etc/ssh/*_config /etc/ssh/
chmod 644 /etc/ssh/*_config
systemctl restart sshd.service

# configure ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw enable
