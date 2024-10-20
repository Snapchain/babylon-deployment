#!/bin/bash
set -euo pipefail

# Load environment variables from the .env.bitcoin file
set -a
source $(pwd)/.env.bitcoin
set +a

if [ -z "$(echo ${BTCSTAKER_WALLET_PASS})" ] || [ -z "$(echo ${BTCSTAKER_PRIVKEY})" ]; then
    echo "Error: BTCSTAKER_WALLET_PASS or BTCSTAKER_PRIVKEY environment variable is not set"
    exit 1
fi
echo "Environment variables loaded successfully"
echo "NETWORK: $NETWORK"
echo "RPC_PORT: $RPC_PORT"
echo

echo "Checking if Bitcoin node is synced..."
SYNCED=$(docker exec bitcoind /bin/sh -c "
    bitcoin-cli \
    -${NETWORK} \
    -rpcuser=${RPC_USER} \
    -rpcpassword=${RPC_PASS} \
    getblockchaininfo" | jq -r '.verificationprogress')
if (( $(awk -v synced="$SYNCED" 'BEGIN {print (synced < 0.999)}') )); then
    echo "Error: Bitcoin node is not fully synced. Expected at least 99.9%, got ${SYNCED}"
    exit 1
fi
echo "Bitcoin node is synced"
echo

# Check btcstaker address
BTCSTAKER_ADDRESS=$(docker exec bitcoind /bin/sh -c "
    bitcoin-cli \
    -${NETWORK} \
    -rpcuser=${RPC_USER} \
    -rpcpassword=${RPC_PASS} \
    -rpcwallet=${BTCSTAKER_WALLET_NAME} \
    getaddressesbylabel \"${BTCSTAKER_WALLET_NAME}\"" \
    | jq -r 'keys[0]')
echo "BTCStaker address: ${BTCSTAKER_ADDRESS}"

# Check if btcstaker has any unspent transactions
BALANCE_BTC=$(docker exec bitcoind /bin/sh -c "
    bitcoin-cli \
    -${NETWORK} \
    -rpcuser=${RPC_USER} \
    -rpcpassword=${RPC_PASS} \
    -rpcwallet=${BTCSTAKER_WALLET_NAME} \
    listunspent" | jq -r '[.[] | .amount] | add')
if (( $(awk -v balance="$BALANCE_BTC" 'BEGIN {print (balance < 0.01)}') )); then
    echo "Warning: BTCStaker balance is less than 0.01 BTC. You may need to fund this address for ${NETWORK}."
else
    echo "BTCStaker balance is sufficient: ${BALANCE_BTC} BTC"
fi
echo