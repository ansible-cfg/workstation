


iptables -t raw -A PREROUTING -p tcp -m tcp --dport 80 -j TRACE -m comment --comment "log 80 preroute"
iptables -t raw -A OUTPUT -p tcp -m tcp --dport 80 -j TRACE -m comment --comment "log 80 output"