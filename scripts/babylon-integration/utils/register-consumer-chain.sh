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
# TODO: for now, we can use the consumer chain name as the consumer description,
# remove it after issue #255 (https://github.com/babylonlabs-io/babylon/issues/255) is fixed
echo "Registering consumer chain $CONSUMER_ID..."
CONSUMER_REGISTRATION_TX_HASH=$(babylond tx btcstkconsumer register-consumer \
    "$CONSUMER_ID" \
    "$CONSUMER_CHAIN_NAME" \
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

# wait for the transaction to be included in a block
echo "Waiting for the transaction to be included in a block..."
wait_for_tx "$CONSUMER_REGISTRATION_TX_HASH" 10 5

# check chain registered
echo "Checking if the chain is registered..."

# query all registered consumer chains
echo "Querying all registered consumer chains..."
CONSUMER_IDS=$(babylond query btcstkconsumer registered-consumers \
    --chain-id $BABYLON_CHAIN_ID \
    --node $BABYLON_RPC_URL \
    -o json | jq -r '.consumer_ids[]')

# check if the consumer chain is registered, if not exit with error
if echo "$CONSUMER_IDS" | grep -q "^${CONSUMER_ID}$"; then
    echo "Consumer chain $CONSUMER_ID successfully registered"
else
    echo "Consumer chain $CONSUMER_ID failed to register"
    exit 1
fi