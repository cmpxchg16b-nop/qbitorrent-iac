#!/bin/bash
set -euo pipefail

ROUTER_CONTAINER=bird
QB_NETNS=/run/netns/qb
DN42_IP=172.16.143.29/32
DN42_IP6=fdda:8ca4:1556:4172::1/64
DN42_GW_IP6=fdda:8ca4:1556:4172::/64

# Strip prefix length for use as route nexthop
DN42_GW_IP6_ADDR="${DN42_GW_IP6%/*}"

# --- Get PID of router container ---
ROUTER_PID=$(docker inspect --format '{{.State.Pid}}' "$ROUTER_CONTAINER")

# --- Create veth pair ---
ip link add v-qb type veth peer name v-dn42

# Move v-qb into the router container's network namespace
ip link set v-qb netns "$ROUTER_PID"

# Move v-dn42 into QB_NETNS
ip link set v-dn42 netns "$QB_NETNS"

# --- Activate interfaces ---
nsenter -t "$ROUTER_PID" -n ip link set v-qb up
ip netns exec "$QB_NETNS" ip link set v-dn42 up

# --- Assign addresses ---
# v-qb (gateway side): IPv6 only
nsenter -t "$ROUTER_PID" -n ip addr add "$DN42_GW_IP6" dev v-qb

# v-dn42 (our side): IPv4 + IPv6
ip netns exec "$QB_NETNS" ip addr add "$DN42_IP" dev v-dn42
ip netns exec "$QB_NETNS" ip addr add "$DN42_IP6" dev v-dn42

# --- Assign routes ---
# IPv4 routes with IPv6 nexthop (Linux extended nexthop / RFC 5549)
ip netns exec "$QB_NETNS" ip route add 172.20.0.0/14 via "$DN42_GW_IP6_ADDR" dev v-dn42
ip netns exec "$QB_NETNS" ip route add 10.127.0.0/16 via "$DN42_GW_IP6_ADDR" dev v-dn42

# IPv6 route
ip netns exec "$QB_NETNS" ip -6 route add fd00::/8 via "$DN42_GW_IP6_ADDR" dev v-dn42
