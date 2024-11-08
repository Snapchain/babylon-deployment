#!/bin/bash
set -uo pipefail

# Set keyring directory
KEYRING_DIR=/home/.babylond

# query all registered consumer chains
echo "Querying all registered consumer chains..."
CONSUMER_IDS=$(babylond query btcstkconsumer registered-consumers \
    --chain-id $BABYLON_CHAIN_ID \
    --node $BABYLON_RPC_URL \
    -o json | jq -r '.consumer_ids[]')

# check if the consumer chain is already registered
if echo "$CONSUMER_IDS" | grep -q "^${CONSUMER_ID}$"; then
    echo "Consumer chain $CONSUMER_ID is already registered"
    exit 0
fi

# register the consumer chain
echo "Registering consumer chain $CONSUMER_ID..."
CONSUMER_REGISTRATION_TX_HASH=$(babylond tx btcstkconsumer register-consumer \
    "$CONSUMER_ID" \
    "$CONSUMER_CHAIN_NAME" \
    --chain-id $BABYLON_CHAIN_ID \
    --node $BABYLON_RPC_URL \
    --from $BABYLON_PREFUNDED_KEY \
    --keyring-dir $KEYRING_DIR \
    --keyring-backend test \
    --gas-prices 0.2ubbn \
    --gas auto \
    --gas-adjustment 2 \
    -o json -y \
    | jq -r '.txhash')
echo "Consumer registration transaction hash: $CONSUMER_REGISTRATION_TX_HASH"
echo