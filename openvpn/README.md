# OpenVPN Setup

To install and configure OpenVPN run:
```bash
./openvpn-install-new.sh
```

To add a new client run:
```bash
./openvpn-gen-client-new.sh
```
You will be prompted for a name for the client, for example let's use `newclient`.
The client's config files will be saved at `/etc/openvpn/client/newclient.tgz`.

Legacy scripts for older versions of OpenVPN can be found in the `old` directory.
