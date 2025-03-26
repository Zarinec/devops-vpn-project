#!/bin/bash
iptables -F
iptables -t nat -F
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables-save > /etc/iptables/rules.v4
echo "Firewall rules reset to default!"
