# Server Setup

Setup scripts for a fresh Debian (trixie) server: system packages, an admin user, hardened SSH host keys and configuration, unattended upgrades, and a UFW firewall.

## Usage
To run the setup script, first clone the repo, then change into it and run `setup.sh` as root:
```bash
git clone https://github.com/cameronperot/server-setup.git
cd server-setup
./setup.sh
```

The script prompts for the new user's password (this password is needed for `sudo`) and asks whether to regenerate the SSH host keys.

Actions taken:
- Installs and updates packages and switches apt to the deb822 sources in `etc/apt/`.
- Creates a new user with sudo access and configures key-only SSH login for them (the username is hardcoded in `NEW_USER` at the top of `setup.sh`).
- Enables unattended upgrades and installs fail2ban (with Debian's default sshd jail).
- Deploys the SSH configuration from `etc/ssh/` and the pre-login banner `etc/issue.net`, validating the configuration with `sshd -t` before restarting sshd.
- Enables UFW: all incoming traffic denied except SSH, all outgoing traffic allowed.

Files that are replaced (`/etc/apt/sources.list` and the contents of `/etc/ssh`, including host keys) are first backed up to `/var/backups/server-setup/<timestamp>/`. The script can safely be run again.

### Additional Scripts
The `scripts` directory of this repo contains additional scripts to install additional packages such as Docker, Podman, and Syncthing. Each must also be run as root.
