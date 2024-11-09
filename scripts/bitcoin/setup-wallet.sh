#!/bin/bash
set -euo pipefail

echo "NETWORK: $NETWORK"
echo "BTC_WALLET_NAME: $BTC_WALLET_NAME"

DATA_DIR=/bitcoind/.bitcoin

if [[ ! -d "${DATA_DIR}/${NETWORK}/wallets/${BTC_WALLET_NAME}" ]]; then
  echo "Creating a wallet ${BTC_WALLET_NAME}..."
  bitcoin-cli -${NETWORK} -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" createwallet "$BTC_WALLET_NAME" false false "$BTC_WALLET_PASS" false false
fi

echo "Opening wallet ${BTC_WALLET_NAME}..."
bitcoin-cli -${NETWORK} -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$BTC_WALLET_NAME" walletpassphrase "$BTC_WALLET_PASS" 10
echo "Importing the private key to the wallet ${BTC_WALLET_NAME} with the label ${BTC_WALLET_NAME} without rescan..."
bitcoin-cli -${NETWORK} -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$BTC_WALLET_NAME" importprivkey "$BTC_PRIVKEY" "${BTC_WALLET_NAME}" false

if [[ "$NETWORK" == "regtest" ]]; then
  echo "Generating 110 blocks for the first coinbases to mature..."
  bitcoin-cli -${NETWORK} -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$BTC_WALLET_NAME" -generate 110

  # Waiting for the wallet to catch up.
  sleep 5
  echo "Checking balance..."
  bitcoin-cli -${NETWORK} -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$BTC_WALLET_NAME" getbalance
  
  echo "Getting the imported BTC address for wallet ${BTC_WALLET_NAME}..."
  BTC_ADDR=$(bitcoin-cli -${NETWORK} -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$BTC_WALLET_NAME" getaddressesbylabel "${BTC_WALLET_NAME}" | jq -r 'keys[0]')
  echo "Imported BTC address: ${BTC_ADDR}"

  if [[ -z "$GENERATE_INTERVAL_SECS" ]]; then
    GENERATE_INTERVAL_SECS=600 # 10 minutes
  fi

  # without it, regtest will not mine blocks
  echo "Starting block generation every $GENERATE_INTERVAL_SECS seconds in the background..."
  (
    while true; do
      bitcoin-cli -${NETWORK} -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$BTC_WALLET_NAME" -generate 1
      sleep "$GENERATE_INTERVAL_SECS"
    done
  ) &
fi