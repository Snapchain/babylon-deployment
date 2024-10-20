#!/bin/bash
set -euo pipefail

echo "NETWORK: $NETWORK"
echo "BTCSTAKER_WALLET_NAME: $BTCSTAKER_WALLET_NAME"

DATA_DIR=/bitcoind/.bitcoin

if [[ ! -d "${DATA_DIR}/${NETWORK}/wallets/${BTCSTAKER_WALLET_NAME}" ]]; then
  echo "Creating a wallet for btcstaker..."
  bitcoin-cli -${NETWORK} -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" createwallet "$BTCSTAKER_WALLET_NAME" false false "$BTCSTAKER_WALLET_PASS" false false
fi

echo "Opening ${BTCSTAKER_WALLET_NAME} wallet..."
bitcoin-cli -${NETWORK} -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$BTCSTAKER_WALLET_NAME" walletpassphrase "$BTCSTAKER_WALLET_PASS" 10
echo "Importing the private key to the wallet ${BTCSTAKER_WALLET_NAME} with the label ${BTCSTAKER_WALLET_NAME} without rescan..."
bitcoin-cli -${NETWORK} -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$BTCSTAKER_WALLET_NAME" importprivkey "$BTCSTAKER_PRIVKEY" "${BTCSTAKER_WALLET_NAME}" false

if [[ "$NETWORK" == "regtest" ]]; then
  echo "Generating 110 blocks for the first coinbases to mature..."
  bitcoin-cli -${NETWORK} -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$BTCSTAKER_WALLET_NAME" -generate 110

  # Waiting for the wallet to catch up.
  sleep 5
  echo "Checking balance..."
  bitcoin-cli -${NETWORK} -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$BTCSTAKER_WALLET_NAME" getbalance
  
  echo "Getting the imported BTC address for wallet ${BTCSTAKER_WALLET_NAME}..."
  BTCSTAKER_ADDR=$(bitcoin-cli -${NETWORK} -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$BTCSTAKER_WALLET_NAME" getaddressesbylabel "${BTCSTAKER_WALLET_NAME}" | jq -r 'keys[0]')
  echo "Imported BTC address: ${BTCSTAKER_ADDR}"

  if [[ -z "$GENERATE_INTERVAL_SECS" ]]; then
    GENERATE_INTERVAL_SECS=600 # 10 minutes
  fi

  # without it, regtest will not mine blocks
  echo "Starting block generation every $GENERATE_INTERVAL_SECS seconds in the background..."
  (
    while true; do
      bitcoin-cli -${NETWORK} -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$BTCSTAKER_WALLET_NAME" -generate 1
      sleep "$GENERATE_INTERVAL_SECS"
    done
  ) &
fi