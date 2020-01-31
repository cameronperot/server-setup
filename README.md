# Server Setup

## Usage

Before running the script you will want to change the `new_user`, `ssh_key1`, and `ssh_key2` variables in `server-setup.sh`. to your desired values.

```bash
git clone https://github.com/cameronperot/server-setup.git
cd server-setup
./server-setup.sh <IPTABLES_RULESET> <DEV>
```

Where:
* `<IPTABLES_RULESET>` is one of `[standard, vpn]` depending on which iptables ruleset you would like to use.
* `<DEV>` is `true` if you wish to install additional development packages, otherwise leave blank.

