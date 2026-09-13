#!/usr/bin/env bash
#
# setup-networkd.sh — switch Debian from ifupdown to systemd-networkd.
#
# Usage: setup-networkd.sh [-a CIDR -g GW] [-d SERVERS]...
#
# Writes /etc/systemd/network/20-wired.network (DHCP by default, static
# with -a/-g), enables systemd-resolved and systemd-networkd, then
# disables ifupdown. Run it from a console or multiplexer: connectivity
# drops briefly while the services are switched.

set -euo pipefail

readonly NETWORK_FILE=/etc/systemd/network/20-wired.network
readonly RESOLV_CONF=/run/systemd/resolve/stub-resolv.conf
readonly INTERFACES_FILE=/etc/network/interfaces

address=
gateway=
declare -a dns_servers=()

usage() {
    cat <<EOF
Usage: ${0##*/} [options]

Switch Debian networking from ifupdown to systemd-networkd.
Without options the wired interface is configured via DHCP.

Options:
  -h, --help          show this help
  -a, --address CIDR  static address, e.g. 192.168.1.123/24 (requires -g)
  -g, --gateway GW    default gateway, e.g. 192.168.1.1 (requires -a)
  -d, --dns SERVERS   DNS servers for static mode, e.g. "1.1.1.1 8.8.8.8"
                      (repeatable); ignored in DHCP mode

Examples:
  ${0##*/}
  ${0##*/} -a 192.168.1.123/24 -g 192.168.1.1
  ${0##*/} -a 192.168.1.123/24 -g 192.168.1.1 -d "1.1.1.1 8.8.8.8"
EOF
}

die() {
    echo "${0##*/}: error: $*" >&2
    exit 1
}

warn() {
    echo "${0##*/}: warning: $*" >&2
}

while (($# > 0)); do
    case "$1" in
    -h | --help)
        usage
        exit 0
        ;;
    -a | --address)
        (($# >= 2)) || die "$1 needs a value"
        address="$2"
        shift 2
        ;;
    -g | --gateway)
        (($# >= 2)) || die "$1 needs a value"
        gateway="$2"
        shift 2
        ;;
    -d | --dns)
        (($# >= 2)) || die "$1 needs a value"
        dns_servers+=("$2")
        shift 2
        ;;
    *)
        usage >&2
        die "unknown option: $1"
        ;;
    esac
done

if [[ -n "${address}" || -n "${gateway}" ]]; then
    [[ -n "${address}" && -n "${gateway}" ]] \
        || die "-a and -g must be given together for a static configuration"
fi

((EUID == 0)) || die "this script must be run as root"

if ! compgen -G '/sys/class/net/en*' >/dev/null \
    && ! compgen -G '/sys/class/net/eth*' >/dev/null; then
    warn "no en* or eth* interface found; check 'ip -br link'"
fi

{
    echo "[Match]"
    echo "Name=en* eth*"
    echo ""
    echo "[Network]"
    if [[ -n "${address}" ]]; then
        echo "Address=${address}"
        echo "Gateway=${gateway}"
        for dns in "${dns_servers[@]}"; do
            echo "DNS=${dns}"
        done
    else
        echo "DHCP=yes"
    fi
} >"${NETWORK_FILE}"
echo "wrote ${NETWORK_FILE}"

systemctl enable --now systemd-resolved
ln -sf "${RESOLV_CONF}" /etc/resolv.conf

# Bring networkd up before stopping ifupdown so connectivity is preserved.
systemctl enable --now systemd-networkd

systemctl disable --now networking
if [[ -f "${INTERFACES_FILE}" ]]; then
    mv "${INTERFACES_FILE}" "${INTERFACES_FILE}.bak"
    echo "moved ${INTERFACES_FILE} to ${INTERFACES_FILE}.bak"
fi

networkctl
