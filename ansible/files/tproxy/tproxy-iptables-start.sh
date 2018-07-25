#!/bin/bash

sudo iptables -w -t nat -D PREROUTING -p tcp -m comment --comment "transparent proxy http redirect docker/vm" -m tcp --dport 80 -j SQUID
sudo iptables -w -t nat -D PREROUTING -p tcp -m comment --comment "transparent proxy https redirect docker/vm" -m tcp --dport 443 -j SQUID
sudo iptables -w -t nat -D OUTPUT -p tcp -m comment --comment "transparent proxy http redirect" -m tcp --dport 80 -j SQUID
sudo iptables -w -t nat -D OUTPUT -p tcp -m comment --comment "transparent proxy https redirect" -m tcp --dport 443 -j SQUID

sudo iptables -w -t nat -F SQUID
sudo iptables -w -t nat -X SQUID

sudo iptables -w -D INPUT -i eth0 -p tcp -m comment --comment "transparent proxy restrict to host" -m tcp --dport 3128:3130 -j DROP

set -e
set -x

sudo iptables -w -t nat -N SQUID
sudo iptables -w -t nat -A SQUID -m comment --comment "localhost" -d 127.0.0.1 -j RETURN
sudo iptables -w -t nat -A SQUID -m comment --comment "RFC1918 network" -d 10.0.0.0/8 -j RETURN
sudo iptables -w -t nat -A SQUID -m comment --comment "RFC1918 network" -d 172.16.0.0/12 -j RETURN
sudo iptables -w -t nat -A SQUID -m comment --comment "RFC1918 network" -d 192.168.0.0/16 -j RETURN
# corporate networks
{% for item in proxy.no_proxy_cidrs %}
sudo iptables -w -t nat -A SQUID -m comment --comment "corpnet {{ item.comment }}" -d {{ item.cidr }} -j RETURN
{% endfor %}

# rules for logging
sudo iptables -w -t nat -A SQUID -m comment --comment "log http redirects" -p tcp --dport 80 -j LOG --log-prefix "squid-http "
sudo iptables -w -t nat -A SQUID -m comment --comment "log https redirects" -p tcp --dport 443 -j LOG --log-prefix "squid-https "

# redirect to squid
sudo iptables -w -t nat -A SQUID -m comment --comment "redirect http" -p tcp --dport 80 -j REDIRECT --to 3129
sudo iptables -w -t nat -A SQUID -m comment --comment "redirect https" -p tcp --dport 443 -j REDIRECT --to 3129

sudo iptables -w -t nat -I PREROUTING 1 -p tcp -m comment --comment "transparent proxy http redirect docker/vm" -m tcp --dport 80 -j SQUID
sudo iptables -w -t nat -I PREROUTING 1 -p tcp -m comment --comment "transparent proxy https redirect docker/vm" -m tcp --dport 443 -j SQUID

sudo iptables -w -t nat -I OUTPUT 1 -p tcp -m comment --comment "transparent proxy http redirect" -m tcp --dport 80 -j SQUID
sudo iptables -w -t nat -I OUTPUT 1 -p tcp -m comment --comment "transparent proxy https redirect" -m tcp --dport 443 -j SQUID

sudo iptables -w -A INPUT -i eth0 -p tcp -m comment --comment "transparent proxy restrict to host" -m tcp --dport 3128:3130 -j DROP
