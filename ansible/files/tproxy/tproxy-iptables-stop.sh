#!/bin/bash

set -e
set -x

sudo iptables -w -t nat -D PREROUTING -p tcp -m comment --comment "transparent proxy http redirect docker/vm" -m tcp --dport 80 -j SQUID
sudo iptables -w -t nat -D PREROUTING -p tcp -m comment --comment "transparent proxy https redirect docker/vm" -m tcp --dport 443 -j SQUID
sudo iptables -w -t nat -D OUTPUT -p tcp -m comment --comment "transparent proxy http redirect" -m tcp --dport 80 -j SQUID
sudo iptables -w -t nat -D OUTPUT -p tcp -m comment --comment "transparent proxy https redirect" -m tcp --dport 443 -j SQUID

sudo iptables -w -t nat -F SQUID
sudo iptables -w -t nat -X SQUID

sudo iptables -w -D INPUT -i eth0 -p tcp -m comment --comment "transparent proxy restrict to host" -m tcp --dport 3128:3130 -j DROP
