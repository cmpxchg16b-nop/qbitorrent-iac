#!/bin/bash
set -euo pipefail

# Destroy the qb network namespace.
#
# This must run after all veth pairs have been torn down, as deleting
# a netns with interfaces still present can leave orphaned interfaces.

QB_NETNS=qb

log() { echo "[netns] $*"; }

log "Destroying network namespace $QB_NETNS"
ip netns del "$QB_NETNS"

log "Done"
