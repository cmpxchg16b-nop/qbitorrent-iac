#!/bin/bash
set -euo pipefail

# Tear down host veth pair (v-qb on host <-> eth0 in qb netns)
#
# Deleting one end of a veth pair removes the other end as well.
# Associated addresses and routes are cleaned up automatically.

log() { echo "[host-nw] $*"; }

log "Destroying v-qb on host (eth0 in qb netns will be removed too)"
ip link del v-qb

log "Done"
