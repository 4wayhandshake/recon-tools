#!/bin/bash

USAGE="Usage: $0 {target specification}\n    The argument can be an IP address, IP range, CIDR address, etc.\n    Use anything that nmap would accept as a target specification."

if [ $# -gt 0 ]; then
    TARGET=$1
else
    echo -e "$USAGE"
    exit 1
fi

SCRIPT_DIR=$(dirname "$(realpath -s "$0")")

# Run host_discovery.sh
. "$SCRIPT_DIR/host_discovery.sh" "$TARGET"

# Check if ip-list.txt exists
if [ ! -f "$SCRIPT_DIR/host-discovery/ip-list.txt" ]; then
    echo -e "Could not run nmap scripts on specified target(s):\n    File not found: $SCRIPT_DIR/host-discovery/ip-list.txt"
    exit 1
fi

# For each IP in ip-list.txt, run scan_host.sh
while read -r IP; do
    echo -e "\n\n==== SCANNING HOST: $IP ================"
    . "$SCRIPT_DIR/scan_host.sh" "$IP"
done < "$SCRIPT_DIR/host-discovery/ip-list.txt"

xdg-open "$SCRIPT_DIR/index.html"
