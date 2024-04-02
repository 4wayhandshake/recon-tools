#!/bin/bash

USAGE="Usage: $0 {target specification}\n    The argument can be an IP address, IP range, CIDR address, etc.\n    Use anything that nmap would accept as a target specification."

if [ $# -gt 0 ]; then
    TARGET=$1
else
    echo -e "$USAGE"
    exit 1
fi

SCRIPT_DIR=$(dirname "$(realpath -s "$0")")
mkdir -p "$SCRIPT_DIR/host-discovery"
echo -e "Performing host discovery on: $TARGET ..."

# Perform the scan
sudo nmap -sn -T4 --reason -oN "$SCRIPT_DIR/host-discovery/discovery.txt" -oX "$SCRIPT_DIR/host-discovery/discovery.xml" "$TARGET" | \
	grep 'scan report for' | \
	grep -oE '([0-9]{1,3}.){3}[0-9]{1,3}' | \
	sed 's/[()]//g' | \
	sort -t. -n -k1,1 -k2,2 -k3,3 -k4,4 > "$SCRIPT_DIR/host-discovery/ip-list.txt"
	
# Parse the XML into HTML
xsltproc "$SCRIPT_DIR/host-discovery/discovery.xml" -o "$SCRIPT_DIR/host-discovery/discovery.html"
rm -f "$SCRIPT_DIR/host-discovery/discovery.xml"

# Display the result
echo -e "\n\nDISCOVERED HOSTS:\n"
cat "$SCRIPT_DIR/host-discovery/discovery.txt" | grep 'scan report for' | awk -F 'scan report for' '{print $2}'
