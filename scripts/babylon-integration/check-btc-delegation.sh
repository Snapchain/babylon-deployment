#!/bin/bash
set -euo pipefail

echo "Checking BTC delegation status..."
echo "DELEGATION_ACTIVE means the delegation is active (if there are multiple delegations, monitor the latest one)"
docker exec btc-staker /bin/sh -c "/bin/stakercli daemon list-staking-transactions"
echo