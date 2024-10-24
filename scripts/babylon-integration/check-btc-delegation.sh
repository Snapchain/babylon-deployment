#!/bin/bash
set -euo pipefail

echo "Checking BTC delegation status..."
echo "DELEGATION_ACTIVE means the delegation is active"
docker exec btc-staker /bin/sh -c "/bin/stakercli daemon list-staking-transactions"
echo