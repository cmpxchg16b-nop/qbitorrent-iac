#!/bin/bash

ip l add v-qb type veth peer eth0 netns qb
ip l set v-qb up
ip -n qb l set eth0 up

ip a add 10.169.254.2/30 dev v-qb
ip -n qb a add 10.169.254.1/30 dev eth0

ip -6 a add fd96:4158:7963::2/64 dev v-qb
ip -n qb -6 a add fd96:4158:7963::1/64 dev eth0

ip -n qb route add default via 10.169.254.2
ip -n qb -6 route add default via fd96:4158:7963::2

sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1

nft add table ip qb-nat
nft add chain ip qb-nat postrouting '{ type nat hook postrouting priority srcnat ; policy accept ; }'
nft add rule ip qb-nat postrouting ip saddr 10.169.254.0/30 oifname "v-qb" accept
nft add rule ip qb-nat postrouting ip saddr 10.169.254.0/30 masquerade

nft add chain ip qb-nat prerouting '{ type nat hook prerouting priority dstnat ; policy accept ; }'
nft add rule ip qb-nat prerouting tcp dport 6881 dnat to 10.169.254.1:6881

nft add table ip6 qb-nat6
nft add chain ip6 qb-nat6 postrouting '{ type nat hook postrouting priority srcnat ; policy accept ; }'
nft add rule ip6 qb-nat6 postrouting ip6 saddr fd96:4158:7963::/64 oifname "v-qb" accept
nft add rule ip6 qb-nat6 postrouting ip6 saddr fd96:4158:7963::/64 masquerade

nft add chain ip6 qb-nat6 prerouting '{ type nat hook prerouting priority dstnat ; policy accept ; }'
nft add rule ip6 qb-nat6 prerouting tcp dport 6881 dnat to fd96:4158:7963::1:6881
