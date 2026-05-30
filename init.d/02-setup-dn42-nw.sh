#!/bin/bash
set -euo pipefail

ROUTER_CONTAINER=bird
APP_NETNS=/run/netns/qb
DN42_IP=172.20.143.48/32
DN42_IP6=fdda:8ca4:1556:a008::1/64
DN42_IP6_ADDR="${DN42_IP6%/*}"
DN42_GW_IP6=fdda:8ca4:1556:a008::/64

log() { echo "[dn42-nw] $*"; }

# Strip prefix length for use as route nexthop
DN42_GW_IP6_ADDR="${DN42_GW_IP6%/*}"
log "  DN42_GW_IP6_ADDR=$DN42_GW_IP6_ADDR"

# --- Get PID of router container ---
log "Getting PID of container $ROUTER_CONTAINER"
ROUTER_PID=$(docker inspect --format '{{.State.Pid}}' "$ROUTER_CONTAINER")
log "  PID=$ROUTER_PID"

# --- Create veth pair (one-liner with netns) ---
log "Creating veth pair: v-qb1 (ns=$ROUTER_PID) <-> v-dn42 (ns=$APP_NETNS)"
ip link add v-qb1 netns "$ROUTER_PID" type veth peer v-dn42 netns "$APP_NETNS"

# --- Activate interfaces ---
log "Activating v-qb1 in container $ROUTER_CONTAINER"
nsenter -t "$ROUTER_PID" -n ip l set v-qb1 vrf vrf42
nsenter -t "$ROUTER_PID" -n ip link set v-qb1 up

log "Activating v-dn42 in $APP_NETNS"
nsenter --net="$APP_NETNS" ip link set v-dn42 up

# --- Assign addresses ---
log "Assigning $DN42_GW_IP6 to v-qb1"
nsenter -t "$ROUTER_PID" -n ip addr add "$DN42_GW_IP6" dev v-qb1

log "Assigning $DN42_IP and $DN42_IP6 to v-dn42"
nsenter --net="$APP_NETNS" ip addr add "$DN42_IP" dev v-dn42
nsenter --net="$APP_NETNS" ip addr add "$DN42_IP6" dev v-dn42

# --- Assign routes ---
log "Adding route 172.20.0.0/14 via $DN42_GW_IP6_ADDR (extended nexthop)"
nsenter --net="$APP_NETNS" ip route add 172.20.0.0/14 via inet6 "$DN42_GW_IP6_ADDR" dev v-dn42

log "Adding route 10.127.0.0/16 via $DN42_GW_IP6_ADDR (extended nexthop)"
nsenter --net="$APP_NETNS" ip route add 10.127.0.0/16 via inet6 "$DN42_GW_IP6_ADDR" dev v-dn42

log "Adding route fd00::/8 via $DN42_GW_IP6_ADDR"
nsenter --net="$APP_NETNS" ip -6 route add fd00::/8 via "$DN42_GW_IP6_ADDR" dev v-dn42

# --- Reverse route: router -> app netns ---
# Since DN42_IP is a /32 host address, the router needs an explicit route
# to reach it back via the veth pair.
log "Adding reverse route to $DN42_IP in container $ROUTER_CONTAINER"
nsenter -t "$ROUTER_PID" -n ip route add "$DN42_IP" via inet6 "$DN42_IP6_ADDR" dev v-qb1 vrf vrf42

log "Done"
