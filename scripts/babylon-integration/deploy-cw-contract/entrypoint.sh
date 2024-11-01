#!/bin/bash
set -euo pipefail

echo "Printing babylond version..."
babylond version
echo

# Deploy the contract
echo "Deploying the contract..."
./deploy-cw-contract.sh
echo "Successfully deployed $CONTRACT_LABEL contract."