#!/usr/bin/env bash
set -eu -o pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd -P )"

# Ensure script is run as root
if [ "$USER" != "root" ]; then
    echo "You must run this script as root!"
    exit 1
fi

# Check that a valid ipruleset was provided
if [[ ! ("$1" == "standard" || "$1" == "vpn") ]]; then
    echo "Invalid iptables ruleset type provided (arg 1), valid options are: [standard, vpn]"
    exit 1
fi

# Username, SSH keys, and location of user's home directory
echo "What would you like the username to be?"
read -r NEW_USER
SSH_KEY1="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOhUSbmv/3Q0vMYLdaNLGcBwvNpGKjLSeBdf/z+JETO1"
HOME_DIR="/home/$NEW_USER"

# Create the new user and add them to the sudo group
adduser --gecos "" "$NEW_USER"
usermod -a -G sudo "$NEW_USER"

# Aliases for the new user
echo "alias ls='ls -lahF --color=always'" >> "$HOME_DIR/.bash_aliases"
chown "$NEW_USER:$NEW_USER" "$HOME_DIR"/.bash_aliases

# Set up the new user's ~/.ssh directory and authorized_keys
mkdir "$HOME_DIR/.ssh"
chmod 700 "$HOME_DIR/.ssh"
echo "$SSH_KEY1" >> "$HOME_DIR/.ssh/authorized_keys"
chmod 600 "$HOME_DIR/.ssh/authorized_keys"
chown -R "$NEW_USER:$NEW_USER" "$HOME_DIR/.ssh"

# Update and install packages
apt-get update
apt-get -y upgrade
apt-get -y install \
    aptitude \
    git \
    rsync \
    tmux \
    sudo \
    vim \
    nload \
    iptables-persistent \
    htop \
    curl \
    ca-certificates \
    unattended-upgrades \
    apt-listchanges

# Install extra dev packages
if [ "${2:-false}" == "true" ]; then
    apt-get -y install \
        libmariadbclient-dev \
        python3-dev \
        libsasl2-dev \
        build-essential \
        postgresql \
        postgresql-contrib
fi

# Configure unattended upgrades
dpkg-reconfigure -plow unattended-upgrades

# Generate server SSH keys (ed25519 and 4096-bit RSA)
cd /etc/ssh
rm ssh_host_*key*
ssh-keygen -t ed25519 -f ssh_host_ed25519_key < /dev/null
ssh-keygen -t rsa -b 4096 -f ssh_host_rsa_key < /dev/null

# Edit the moduli file to remove small primes
awk '$5 > 3071' /etc/ssh/moduli > "${HOME}/moduli"
wc -l "${HOME}/moduli"
mv "${HOME}/moduli" /etc/ssh/moduli

# Replace sshd_config and ssh_config files
cp "$DIR"/etc/issue.net /etc/issue.net
cp "$DIR"/etc/ssh/*_config /etc/ssh/
chmod 644 /etc/ssh/*_config

# Disable ipv6
cat >> /etc/sysctl.conf <<EOT
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOT

# Replace iptables rules and restart iptables/sshd
touch /option.netfilter
update-alternatives --set iptables /usr/sbin/iptables-legacy
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
#update-alternatives --set arptables /usr/sbin/arptables-legacy
#update-alternatives --set ebtables /usr/sbin/ebtables-legacy

rsync -a "$DIR/etc/iptables/$1/" /etc/iptables/
chmod 644 /etc/iptables/rules.v*
iptables-restore /etc/iptables/rules.v4
ip6tables-restore /etc/iptables/rules.v6
systemctl restart sshd
