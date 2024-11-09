#!/bin/bash
set -uo pipefail

source "./common.sh"

# Get the consumer FP address
CONSUMER_FP_KEYRING_DIR=/home/finality-provider/.fpd
KEYRING_FILENAME=$(ls $CONSUMER_FP_KEYRING_DIR/keyring-test | grep '\.address$' | sed 's/\.address$//')
echo "Keyring filename: $KEYRING_FILENAME"
CONSUMER_FP_ADDRESS=$(babylond keys parse "$KEYRING_FILENAME" | grep -o '^[^- ]*' | head -n 1)
echo "Consumer FP address: $CONSUMER_FP_ADDRESS"

# Get the prefunded key address
PREFUNDED_KEYRING_DIR=/home/.babylond
PREFUNDED_ADDRESS=$(babylond keys show "$BABYLON_PREFUNDED_KEY" \
    --keyring-dir "$PREFUNDED_KEYRING_DIR" \
    --keyring-backend test \
    --output json \
    | jq -r '.address')
echo "Prefunded address: $PREFUNDED_ADDRESS"

# Check remaining balance
CONSUMER_FP_BALANCE=$(babylond query bank balances "$CONSUMER_FP_ADDRESS" \
    --node "$BABYLON_RPC_URL" \
    -o json | jq -r '.balances[0].amount')
echo "Consumer FP balance: $CONSUMER_FP_BALANCE"

# If balance is less than gas transfer cost, don't send funds
TRANSFER_GAS_COST=1000
if [ "$CONSUMER_FP_BALANCE" -lt "$TRANSFER_GAS_COST" ]; then
    echo "Consumer FP balance is less than gas transfer cost, skipping funds transfer"
    exit 0
fi

# Otherwise, send out funds to prefunded key
# Reserve 0.001 bbn = 1000 ubbn for gas
AMOUNT_TO_SEND=$((CONSUMER_FP_BALANCE - TRANSFER_GAS_COST))
echo "Sending funds to prefunded key..."
SEND_TX_HASH=$(babylond tx bank send "$CONSUMER_FP_ADDRESS" "$PREFUNDED_ADDRESS" "$AMOUNT_TO_SEND"ubbn \
    --keyring-dir "$CONSUMER_FP_KEYRING_DIR" \
    --chain-id $BABYLON_CHAIN_ID \
    --node $BABYLON_RPC_URL \
    --keyring-backend test \
    --gas auto \
    --gas-adjustment 1.5 \
    --gas-prices 0.2ubbn \
    --dry-run \ # TODO: remove this once ready
    --output json -y \
    | jq -r '.txhash')


# Wait for transaction to complete
if ! wait_for_tx "$SEND_TX_HASH" 10 3; then
    echo "Failed to send funds back to prefunded key"
    exit 1
fi

echo "Successfully sent $AMOUNT_TO_SEND ubbn back to prefunded key"
echo "Transaction hash: $SEND_TX_HASH"
echo

# Verify final balance
FINAL_BALANCE=$(babylond query bank balances "$CONSUMER_FP_ADDRESS" \
    --node "$BABYLON_RPC_URL" \
    -o json | jq -r '.balances[0].amount')
echo "Final consumer FP balance: $FINAL_BALANCE"
