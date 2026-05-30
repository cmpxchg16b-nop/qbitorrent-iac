#!/bin/bash
set -euo pipefail

# Tear down host veth pair (v-qb on host <-> eth0 in qb netns)
#
# Deleting one end of a veth pair removes the other end as well.
# Associated addresses and routes are cleaned up automatically.

log() { echo "[host-nw] $*"; }

log "Deleting nftables tables (chains and rules are removed automatically)"
nft delete table ip qb-nat 2>/dev/null || true
nft delete table ip6 qb-nat6 2>/dev/null || true

log "Destroying v-qb on host (eth0 in qb netns will be removed too)"
ip link del v-qb

log "Done"
