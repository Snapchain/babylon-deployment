#!/bin/bash
set -uo pipefail

source "./common.sh"

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
SET_ENABLED_TX_OUTPUT=$(babylond tx wasm execute $CONTRACT_ADDR \
    '{"set_enabled":{"enabled":'$IS_ENABLED'}}' \
    --gas-prices 0.2ubbn \
    --gas auto \
    --gas-adjustment 1.3 \
    --from $BABYLON_PREFUNDED_KEY \
    --keyring-dir $KEYRING_DIR \
    --chain-id $BABYLON_CHAIN_ID \
    --node $BABYLON_RPC_URL \
    --keyring-backend test \
    -o json -y)
echo "$SET_ENABLED_TX_OUTPUT"
SET_ENABLED_TX_HASH=$(echo "$SET_ENABLED_TX_OUTPUT" | jq -r '.txhash')
echo "Set enabled tx hash: $SET_ENABLED_TX_HASH"

# Wait for the transaction to be included in a block
if ! wait_for_tx "$SET_ENABLED_TX_HASH" 10 3; then
    echo "Failed to set enabled value in contract - transaction failed"
    exit 1
fi

# Query and verify the enabled state
QUERY_ENABLED_VALUE=$(babylond query wasm contract-state smart $CONTRACT_ADDR \
    '{"is_enabled":{}}' \
    --chain-id $BABYLON_CHAIN_ID \
    --node $BABYLON_RPC_URL \
    -o json \
    | jq -r '.data')
echo "Query enabled value: $QUERY_ENABLED_VALUE"

if [ "$QUERY_ENABLED_VALUE" != "$IS_ENABLED" ]; then
    echo "Failed to set enabled value in contract - value mismatch (expected: $IS_ENABLED, got: $QUERY_ENABLED_VALUE)"
    exit 1
fi
echo "Successfully set enabled value to $IS_ENABLED"
echo