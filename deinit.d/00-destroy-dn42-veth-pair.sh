#!/bin/bash
set -euo pipefail

# Tear down dn42 veth pair (v-qb in router container <-> v-dn42 in qb netns)
# and associated routes.
#
# Routes in the qb netns are automatically removed when v-dn42 is deleted.
# Deleting one end of a veth pair removes the other end as well.

ROUTER_CONTAINER=bird
QB_NETNS=/run/netns/qb

log() { echo "[dn42-nw] $*"; }

# Get PID of router container to locate v-qb
log "Getting PID of container $ROUTER_CONTAINER"
ROUTER_PID=$(docker inspect --format '{{.State.Pid}}' "$ROUTER_CONTAINER")

# Destroy v-qb from the router container; v-dn42 in qb netns disappears too
log "Destroying v-qb in container $ROUTER_CONTAINER (PID=$ROUTER_PID)"
nsenter -t "$ROUTER_PID" -n ip link del v-qb

log "Done"
