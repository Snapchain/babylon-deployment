#!/bin/bash
set -euo pipefail

# TODO: don't use test keyring backend in production
echo "Setting Babylon keys..."
# Set keyring directory
KEYRING_DIR=/home/.babylond
CONSUMER_FP_KEYRING_DIR=/home/.consumer-finality-provider

if [ ! -d "$KEYRING_DIR" ]; then
    echo "Creating prefunded keyring directory $KEYRING_DIR"
    mkdir -p $KEYRING_DIR
fi

if [ ! -d "$CONSUMER_FP_KEYRING_DIR" ]; then
    echo "Creating consumer-finality-provider keyring directory $CONSUMER_FP_KEYRING_DIR"
    mkdir -p $CONSUMER_FP_KEYRING_DIR
fi

# Import the Babylon prefunded key
if ! babylond keys show $BABYLON_PREFUNDED_KEY --keyring-dir $KEYRING_DIR --keyring-backend test &> /dev/null; then
    echo "Importing Babylon prefunded key $BABYLON_PREFUNDED_KEY..."
    babylond keys add $BABYLON_PREFUNDED_KEY \
        --keyring-dir $KEYRING_DIR \
        --keyring-backend test \
        --recover <<< "$BABYLON_PREFUNDED_KEY_MNEMONIC"
    echo "Imported Babylon prefunded key $BABYLON_PREFUNDED_KEY"
fi
echo

# Create new Babylon account for the consumer-finality-provider
if ! babylond keys show $CONSUMER_FINALITY_PROVIDER_KEY --keyring-dir $CONSUMER_FP_KEYRING_DIR --keyring-backend test &> /dev/null; then
    echo "Creating key $CONSUMER_FINALITY_PROVIDER_KEY..."
    babylond keys add $CONSUMER_FINALITY_PROVIDER_KEY \
        --keyring-dir $CONSUMER_FP_KEYRING_DIR \
        --keyring-backend test \
        --output json > $CONSUMER_FP_KEYRING_DIR/${CONSUMER_FINALITY_PROVIDER_KEY}.json
    echo "Generated consumer-finality-provider key $CONSUMER_FINALITY_PROVIDER_KEY"
fi
echo

# Fund the consumer-finality-provider account
PREFUNDED_ADDRESS=$(babylond keys show $BABYLON_PREFUNDED_KEY \
    --keyring-dir $KEYRING_DIR \
    --keyring-backend test \
    --output json \
    | jq -r '.address')
CONSUMER_FP_ADDRESS=$(babylond keys show $CONSUMER_FINALITY_PROVIDER_KEY \
    --keyring-dir $CONSUMER_FP_KEYRING_DIR \
    --keyring-backend test \
    --output json \
    | jq -r '.address')
echo "Funding account $CONSUMER_FINALITY_PROVIDER_KEY..."
FUND_TX_HASH=$(babylond tx bank send \
    ${PREFUNDED_ADDRESS} \
    ${CONSUMER_FP_ADDRESS} \
    "${CONSUMER_FP_FUND_AMOUNT_UBBN}ubbn" \
    --chain-id $BABYLON_CHAIN_ID \
    --node $BABYLON_RPC_URL \
    --keyring-dir $KEYRING_DIR \
    --keyring-backend test \
    --gas auto \
    --gas-adjustment 1.5 \
    --gas-prices 0.2ubbn \
    --output json -y \
    | jq -r '.txhash')
echo "Funding transaction hash: $FUND_TX_HASH"
echo