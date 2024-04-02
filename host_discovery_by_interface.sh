#!/bin/bash


USAGE="Usage: $0 <iface> [directory]\nWhere <iface> is the desired network interface, ex. \"wlan0\"\n  and [directory] is the path to a directory to store the results"

if [ $# -gt 0 ]; then
    # Network interface is required
    IFACE=$1
    if [ $# -gt 1 ]; then
        # Trim off a trailing slash if one was provided
        WORKDIR="${2%/}"
    else
        # Use the timestamp
        WORKDIR=nmap-$(date +"%s")
    fi
else
    echo -e "$USAGE"
    exit 1
fi

mkdir -p "$WORKDIR"

# Read the IP and CIDR address of the network interface
CIDR=$(ip addr show $IFACE | grep 'inet ' | grep -oE '([0-9]{1,3}.){4}/[0-9]{1,2}')
IP="${CIDR%%/*}"; NETWORK="${CIDR#*/}"; 

echo -e "Scanning network: $IP/$NETWORK\n"

# Perform the scan
sudo nmap -sn -oN "$WORKDIR/host-discovery.txt" "$CIDR" | \
	grep 'scan report for' | \
	grep -oE '\(.*\)' | \
	sed 's/[()]//g' | \
	sort -t. -n -k1,1 -k2,2 -k3,3 -k4,4 > $WORKDIR/host-discovery-ip-list.txt

# Display the result
cat "$WORKDIR/host-discovery.txt" | grep 'scan report for' | awk -F 'scan report for' '{print $2}'
