#!/bin/bash

USAGE="Usage: $0 [RADDR] \n    Where RADDR is the IP address of the target host. (ex. \"192.168.0.15\")\n    Note that RADDR is required, but alternatively can be passed as a shell/environment variable."
#!/bin/bash

SCRIPT_DIR=$(dirname "$(realpath -s "$0")")

# Define the function to generate HTML for each directory
html=""
generate_html() {
    local dname="$1"
    html+="\n<li><a href=\"./$dname/host.html\"> Host scans for $dname </a><p class=\"note-text\">Scans targeting the host.</p></li>"
}

# If RADDR isnt set, attempt to load it from variables.source if it exists
if [[ ! -v RADDR || -z "$RADDR" ]]; then
    if [ -f "$SCRIPT_DIR/../variables.source" ]; then
        echo "Attempting to source ../variables.source"
        source "$SCRIPT_DIR/../variables.source"
    fi
fi
# Set or overwrite RADDR with the argument if one was provided
if [ $# -gt 0 ]; then
    RADDR=$1
fi
# If it still isn't set, then exit and show usage
if [[ ! -v RADDR || -z "$RADDR" ]]; then
    echo -e "$USAGE"
    exit 1
fi

# Make a directory for the scans of this host
mkdir -p "$SCRIPT_DIR/$RADDR"

# Copy in the page for this scan
cp "$SCRIPT_DIR/host_scan.template" "$SCRIPT_DIR/$RADDR/host.html"
sed -i "s/##RADDR##/$RADDR/g" "$SCRIPT_DIR/$RADDR/host.html"

sudo echo "Running nmap scripts against target: $RADDR ..."

# Run the port scan
echo -e "\n\n==== PORT SCAN:\n"
sudo nmap -p- -n -Pn -T4 --min-rate 1000 -oN "$SCRIPT_DIR/$RADDR/port-scan-tcp.txt" -oX "$SCRIPT_DIR/$RADDR/port-scan-tcp.xml" $RADDR;
xsltproc "$SCRIPT_DIR/$RADDR/port-scan-tcp.xml" -o "$SCRIPT_DIR/$RADDR/port-scan-tcp.html"

# Run the default scripts scan
echo -e "\n\n==== SCRIPT SCAN:\n"
TCPPORTS=`grep "^[0-9]\+/tcp" "$SCRIPT_DIR/$RADDR/port-scan-tcp.txt" | sed 's/^\([0-9]\+\)\/tcp.*/\1/g' | tr '\n' ',' | sed 's/,$//g'`; 
sudo nmap -sV -sC -n -Pn -O -p$TCPPORTS -T4 -oN "$SCRIPT_DIR/$RADDR/script-scan-tcp.txt" -oX "$SCRIPT_DIR/$RADDR/script-scan-tcp.xml" $RADDR; 
xsltproc "$SCRIPT_DIR/$RADDR/script-scan-tcp.xml" -o "$SCRIPT_DIR/$RADDR/script-scan-tcp.html"

# Run the vuln scripts scan
echo -e "\n\n==== VULN SCAN:\n"
sudo nmap -n -Pn -p$TCPPORTS -T4 -oN "$SCRIPT_DIR/$RADDR/vuln-scan-tcp.txt" -oX "$SCRIPT_DIR/$RADDR/vuln-scan-tcp.xml" --script 'safe and vuln' $RADDR
xsltproc "$SCRIPT_DIR/$RADDR/vuln-scan-tcp.xml" -o "$SCRIPT_DIR/$RADDR/vuln-scan-tcp.html"

# Check UDP top-100 ports
echo -e "\n\n==== UDP SCAN:\n"
sudo nmap -sUV -n -Pn -F -T4 --version-intensity 0 -oN "$SCRIPT_DIR/$RADDR/port-scan-udp.txt" -oX "$SCRIPT_DIR/$RADDR/port-scan-udp.xml" $RADDR;
xsltproc "$SCRIPT_DIR/$RADDR/port-scan-udp.xml" -o "$SCRIPT_DIR/$RADDR/port-scan-udp.html"

# Delete all the XML files
rm -f $SCRIPT_DIR/$RADDR/*.xml

# Loop through each directory in the script's directory
for dir in "$SCRIPT_DIR"/*/; do
    dir=$(basename "$dir")
    # Check if the directory name is not "host-discovery"
    if [[ "$dir" != "host-discovery" ]]; then
        generate_html "$dir"
    fi
done

# Output the concatenated HTML
cp "$SCRIPT_DIR/index.template" "$SCRIPT_DIR/index.html"
sed -i "s+##HOST_SCANS##+$html+g" "$SCRIPT_DIR/index.html"
