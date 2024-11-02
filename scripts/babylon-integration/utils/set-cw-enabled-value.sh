#!/bin/bash
set -uo pipefail

# Set keyring directory
KEYRING_DIR=/home/.babylond
# Set contract address output directory
CONTRACT_DIR=/home/.deploy
# Get the IS_ENABLED environment variable
echo "Setting enabled value to $IS_ENABLED"

# Read the contract address
CONTRACT_ADDR=$(cat $CONTRACT_DIR/contract-address.txt | tr -d '[:space:]')
echo "Contract address: $CONTRACT_ADDR"

# Set the is_enabled value in the contract
SET_ENABLED_TX_HASH=$(babylond tx wasm execute $CONTRACT_ADDR \
    '{"set_enabled":{"enabled":'$IS_ENABLED'}}' \
    --from $BABYLON_PREFUNDED_KEY \
    --keyring-dir $KEYRING_DIR \
    --chain-id $BABYLON_CHAIN_ID \
    --node $BABYLON_RPC_URL \
    --keyring-backend test \
    -o json -y \
    | jq -r '.txhash')
echo "Set enabled tx hash: $SET_ENABLED_TX_HASH"

# Verify the is_enabled value in the contract
QUERY_ENABLED_VALUE=$(babylond query wasm contract-state smart $CONTRACT_ADDR \
    '{"is_enabled":{}}' \
    --chain-id $BABYLON_CHAIN_ID \
    --node $BABYLON_RPC_URL \
    -o json \
    | jq -r '.data')
echo "Query enabled value: $QUERY_ENABLED_VALUE"
if [ "$QUERY_ENABLED_VALUE" != "$IS_ENABLED" ]; then
    echo "Failed to set enabled value in contract"
    exit 1
fi