#!/bin/bash
set -e

# Ensure script is run as root
if [ "$USER" != 'root' ]; then
	echo "You must run this script as root!"
	exit 1
fi

# Check that a valid ipruleset was provided
if [[ ! ("$1" == "standard" || "$1" == "vpn") ]]; then
	echo "Invalid iptables ruleset type provided (arg 1), valid options are: [standard, vpn]"
	exit 1
fi

# Directory where config files are located
setup_dir=$PWD

# Username, SSH keys, and location of user's home directory
new_user=cameron
ssh_key1="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKIukxLRRwpbgDxqcsdRY77i7T+Ptsrs8J9tfNrWncHK"
ssh_key2="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO8Nsh7r7SoYZD2JZolMZCJVT9O6OkKlQuQl27YlqQVy"
home_dir=/home/$new_user

# Create the new user and add them to the sudo group
adduser --gecos "" $new_user
usermod -a -G sudo $new_user

# Aliases for the new user
echo "alias ls='ls -lahF --color=always'" >> $home_dir/.bash_aliases
sudo chown $new_user:$new_user $home_dir/.bash_aliases

# Set up the new user's ~/.ssh directory and authorized_keys
mkdir $home_dir/.ssh
chmod 700 $home_dir/.ssh
echo $ssh_key1 >> $home_dir/.ssh/authorized_keys
echo $ssh_key2 >> $home_dir/.ssh/authorized_keys
chmod 600 $home_dir/.ssh/authorized_keys
chown -R $new_user:$new_user $home_dir/.ssh

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
if [ "$2" == "true" ]; then
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
awk '$5 > 2000' /etc/ssh/moduli > "${HOME}/moduli"
wc -l "${HOME}/moduli"
mv "${HOME}/moduli" /etc/ssh/moduli

# Replace sshd_config and ssh_config files
cp $setup_dir/etc/issue.net /etc/issue.net
cp $setup_dir/etc/ssh/*_config /etc/ssh/
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
update-alternatives --set arptables /usr/sbin/arptables-legacy
update-alternatives --set ebtables /usr/sbin/ebtables-legacy

cp $setup_dir/etc/iptables/$1/* /etc/iptables/
chmod 644 /etc/iptables/rules.v*
iptables-restore /etc/iptables/rules.v4
ip6tables-restore /etc/iptables/rules.v6
systemctl restart sshd
