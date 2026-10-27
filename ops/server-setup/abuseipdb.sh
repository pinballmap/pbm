#!/bin/sh
# vim:set ts=2 sts=2 sw=2 et:
# Installed at /usr/local/bin/abuseipdb.sh and run at boot by
# abuseipdb.service. Drops traffic from IPs on the ipsum list (3+ hits) and
# from the hand-kept banned_ips.txt, which isn't in git.

ipset="/sbin/ipset"
iptables="/sbin/iptables"
list=$(mktemp)
banned_ips="/home/dokku/tmp/banned_ips.txt"

wget -O $list https://raw.githubusercontent.com/stamparm/ipsum/master/ipsum.txt

# Create if it doesn't exist
$ipset -q create blackhole hash:ip

# Flush it if it does
$ipset flush blackhole

# -exist skips IPs already in the set; without it, restore stops at the first
# duplicate (e.g. a banned_ips.txt entry that's also on ipsum).
grep -v '#' "$list" | grep -v -E "\s[1-2]$" | cut -f 1 | awk '{print "add blackhole", $1}' | $ipset -exist restore

# Add extra IPs from banned_ips.txt
if [ -f "$banned_ips" ]; then
  grep -v '#' "$banned_ips" | grep -v '^[[:space:]]*$' | awk '{print "add blackhole", $1}' | $ipset -exist restore
fi

if ! $iptables -C INPUT -m set --match-set blackhole src -j DROP 2>/dev/null; then
  $iptables -I INPUT -m set --match-set blackhole src -j DROP
fi

rm -f $list
