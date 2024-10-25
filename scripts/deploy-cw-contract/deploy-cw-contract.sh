#!/bin/bash
set -euo pipefail

# TODO: don't use test keyring backend in production
# Import the key
if ! babylond keys show $CONTRACT_DEPLOYER_KEY --keyring-backend test &> /dev/null; then
    echo "Importing key $CONTRACT_DEPLOYER_KEY..."
    babylond keys add $CONTRACT_DEPLOYER_KEY \
        --recover --keyring-backend test <<< "$CONTRACT_DEPLOYER_KEY_MNEMONIC"
    echo "Key $CONTRACT_DEPLOYER_KEY imported"
fi
echo

# Download the contract
echo "Downloading contract version $CONTRACT_VERSION..."
curl -SL "https://github.com/babylonlabs-io/babylon-contract/releases/download/$CONTRACT_VERSION/${CONTRACT_FILE}.zip" -o "${CONTRACT_FILE}.zip"

# Unzip the contract
CONTRACT_PATH="./artifacts/$CONTRACT_FILE"
echo "Unzipping contract..."
unzip -o "${CONTRACT_FILE}.zip" -d .
# Verify the contract file exists
if [ ! -f "$CONTRACT_PATH" ]; then
    echo "Error: Contract file not found at $CONTRACT_PATH"
    exit 1
fi
echo "Contract is ready at $CONTRACT_PATH"

DEPLOYER_ADDRESS=$(babylond keys show -a $CONTRACT_DEPLOYER_KEY --keyring-backend test)
echo "Deployer address: $DEPLOYER_ADDRESS"
DEPLOYER_BALANCE=$(babylond query bank balances $DEPLOYER_ADDRESS \
    --chain-id $BABYLON_CHAIN_ID \
    --node $BABYLOND_NODE -o json \
    | jq -r '.balances[0].amount')
echo "Deployer balance: $DEPLOYER_BALANCE"

# Store the contract
echo "Storing contract..."
STORE_TX_HASH=$(babylond tx wasm store $CONTRACT_PATH \
    --gas-prices 0.2ubbn \
    --gas auto \
    --gas-adjustment 1.3 \
    --from $DEPLOYER_ADDRESS \
    --chain-id $BABYLON_CHAIN_ID \
    --node $BABYLOND_NODE \
    --keyring-backend test -o json -y \
    | jq -r '.txhash')
echo "Stored contract tx hash: $STORE_TX_HASH"

sleep 30
# Query the code ID
CODE=$(babylond query tx $STORE_TX_HASH \
    --chain-id $BABYLON_CHAIN_ID \
    --node $BABYLOND_NODE -o json \
    | jq -r '.events[] | select(.type == "store_code") | .attributes[] | select(.key == "code_id") | .value')
echo "Code ID: $CODE"

echo "Instantiating contract..."
# Set the contract admin address if it is not already set
if [ -z "$CONTRACT_ADMIN_ADDRESS" ]; then
    CONTRACT_ADMIN_ADDRESS=$DEPLOYER_ADDRESS
    echo "Contract admin address: $CONTRACT_ADMIN_ADDRESS"
fi

INSTANTIATE_MSG_JSON=$(printf '{"admin":"%s","consumer_id":"%s","is_enabled":%s}' \
    "$CONTRACT_ADMIN_ADDRESS" "$CONSUMER_ID" "$IS_ENABLED")
echo "Instantiate message JSON: $INSTANTIATE_MSG_JSON"

# Instantiate the contract
DEPLOY_TX_HASH=$(babylond tx wasm instantiate $CODE "$INSTANTIATE_MSG_JSON" \
    --gas-prices 0.2ubbn \
    --gas auto \
    --gas-adjustment 1.3 \
    --label $CONTRACT_LABEL \
    --admin $CONTRACT_ADMIN_ADDRESS \
    --from $DEPLOYER_ADDRESS \
    --chain-id $BABYLON_CHAIN_ID \
    --node $BABYLOND_NODE \
    --keyring-backend test -o json -y \
    | jq -r '.txhash')
echo "Deployed contract tx hash: $DEPLOY_TX_HASH"

sleep 30
# Query the contract address
echo "Querying contract address..."
CONTRACT_ADDR=$(babylond query tx $DEPLOY_TX_HASH \
    --chain-id $BABYLON_CHAIN_ID \
    --node $BABYLOND_NODE -o json \
    | jq -r '.events[] | select(.type == "instantiate") | .attributes[] | select(.key == "_contract_address") | .value')
echo "Contract address: $CONTRACT_ADDR"

# Query the contract config
echo "Querying contract config..."
QUERY_CONFIG='{"config":{}}'
QUERY_CONSUMER_ID=$(babylond query wasm contract-state smart $CONTRACT_ADDR \
    "$QUERY_CONFIG" \
    --chain-id $BABYLON_CHAIN_ID \
    --node $BABYLOND_NODE -o json \
    | jq -r '.data.consumer_id')
echo "Contract consumer ID: $QUERY_CONSUMER_ID"
if [ "$QUERY_CONSUMER_ID" != "$CONSUMER_ID" ]; then
    echo "Error: Contract consumer ID mismatch"
    exit 1
fi
echo