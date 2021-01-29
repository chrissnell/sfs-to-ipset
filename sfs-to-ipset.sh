#!/bin/bash
set -eo pipefail

# ---------------------------------------------------------------------------------
# CONFIGURATION
# ---------------------------------------------------------------------------------

# SFS IPv4 Addresses (Last 24 hours)
#IPV4_ADDRESS_URL="https://www.stopforumspam.com/downloads/listed_ip_1.zip"
# SFS IPv4 Addresses (Last 7 days)
#IPV4_ADDRESS_URL="https://www.stopforumspam.com/downloads/listed_ip_7.zip"
# SFS IPv4 Addresses (Last 30 days)
#IPV4_ADDRESS_URL="https://www.stopforumspam.com/downloads/listed_ip_30.zip"
# SFS IPv4 Addresses (Last 90 days)
#IPV4_ADDRESS_URL="https://www.stopforumspam.com/downloads/listed_ip_90.zip"
# SFS IPv4 Addresses (Last 180 days)
#IPV4_ADDRESS_URL="https://www.stopforumspam.com/downloads/listed_ip_180.zip"
# SFS IPv4 Addresses (Last year)
#IPV4_ADDRESS_URL="https://www.stopforumspam.com/downloads/listed_ip_365.zip"

IPV4_ADDRESS_URL="https://www.stopforumspam.com/downloads/listed_ip_180.zip"


# SFS IPv6 Addresses (Last 24 hours)
#IPV6_ADDRESS_URL="https://www.stopforumspam.com/downloads/listed_ip_1_ipv6.zip"
# SFS IPv6 Addresses (Last 7 days)
#IPV6_ADDRESS_URL="https://www.stopforumspam.com/downloads/listed_ip_7_ipv6.zip"
# SFS IPv6 Addresses (Last 30 days)
#IPV6_ADDRESS_URL="https://www.stopforumspam.com/downloads/listed_ip_30_ipv6.zip"
# SFS IPv6 Addresses (Last 90 days)
#IPV6_ADDRESS_URL="https://www.stopforumspam.com/downloads/listed_ip_90_ipv6.zip"
# SFS IPv6 Addresses (Last 180 days)
#IPV6_ADDRESS_URL="https://www.stopforumspam.com/downloads/listed_ip_180_ipv6.zip"
# SFS IPv6 Addresses (Last year)
#IPV6_ADDRESS_URL="https://www.stopforumspam.com/downloads/listed_ip_365_ipv6.zip"

IPV6_ADDRESS_URL="https://www.stopforumspam.com/downloads/listed_ip_180_ipv6.zip"

# Set to "no" if you do not want to load IPv6 addresses
DO_IPV6="yes"

# The names of your IPv4 and IPv6
IPV4_IPSET_NAME="sfs-ipv4"
IPV6_IPSET_NAME="sfs-ipv6"

# The maximum number of addresses that your ipsets will ever hold.
# This is required by ipset(8).  I recommend choosing something around
# 2x of the current size of the SFS lists
MAX_ADDRESSES=500000

# ---------------------------------------------------------------------------------
# END OF CONFIGURATION
# ---------------------------------------------------------------------------------

download_and_load_list () {
    # Create a temporary directory to hold the downloaded ZIP files
    TMPDIR=$(mktemp -d)
    
    cd "$TMPDIR"
    
    LIST_URL=$1
    IPSET_NAME=$2
    IPSET_MAXELEMENTS=$3
    IP_FAMILY=$4
    
    echo "Downloading SFS IP list..."
    curl -OL "$LIST_URL"
    
    # Figure out our filename from the URL. SBS ZIP files contain a .txt file of the same name.
    ZIP_FILE=$(echo "$LIST_URL" | sed -r 's/http.*\/(.*.zip)/\1/')
    LIST_FILE=${ZIP_FILE//zip/txt}
    IPSET_FILE="${LIST_FILE}.ipset.txt"
    
    unzip "$ZIP_FILE"
    
    LIST_SIZE=$(wc -l "$LIST_FILE")
    
    # cat ${IPV4_LIST_FILE} |awk '{ print "add $IPV4_IPSET_NAME " $1 }' > "$IPSET_FILE"
    awk -v ipset_name="$IPSET_NAME" '{ print "add " ipset_name " " $1 }' < "$LIST_FILE" > "$IPSET_FILE"
    
    echo "Creating ipset $IPSET_NAME if it does not exist..."
    ipset create "$IPSET_NAME" hash:ip maxelem "$IPSET_MAXELEMENTS" family "$IP_FAMILY" || echo "Skipping ipset creation because set $IPSET_NAME exists"
    echo "Flushing ipset $IPSET_NAME..."
    ipset flush "$IPSET_NAME"
    
    echo "Loading $LIST_SIZE addresses into ipset..."
    ipset restore < "$IPSET_FILE"
    
    echo "Cleaning up..."
    cd /tmp && rm -rf "$TMPDIR"
}

echo "Processing SFS IPv4 list..."
download_and_load_list "$IPV4_ADDRESS_URL" "$IPV4_IPSET_NAME" "$MAX_ADDRESSES" "inet"

if [ "$DO_IPV6" == "yes" ]; then
    echo "Processing SFS IPv6 list..."
    download_and_load_list "$IPV6_ADDRESS_URL" "$IPV6_IPSET_NAME" "$MAX_ADDRESSES" "inet6"
fi