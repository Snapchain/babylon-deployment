#!/bin/bash
set -euo pipefail

echo "NETWORK: $NETWORK"
echo "RPC PORT: $RPC_PORT"

if [[ "$NETWORK" != "regtest" && "$NETWORK" != "signet" ]]; then
  echo "Unsupported network: $NETWORK"
  exit 1
fi

if [[ "$NETWORK" == "regtest" && -z "$GENERATE_INTERVAL_SECS" ]]; then
  GENERATE_INTERVAL_SECS=10
  echo "GENERATE_INTERVAL_SECS not set, using default: $GENERATE_INTERVAL_SECS"
fi

DATA_DIR="/bitcoind/.bitcoin"
CONF=/bitcoind/bitcoin.conf

echo "Generating bitcoin.conf file at $CONF"
NETWORK_LABEL="$NETWORK"
cat <<EOF > "$CONF"
# Enable ${NETWORK} mode.
${NETWORK}=1

# Accept command line and JSON-RPC commands
server=1

# RPC user and password.
rpcuser=$RPC_USER
rpcpassword=$RPC_PASS

# ZMQ notification options.
# Enable publish hash block and tx sequence
zmqpubsequence=tcp://*:$ZMQ_SEQUENCE_PORT
# Enable publishing of raw block hex.
zmqpubrawblock=tcp://*:$ZMQ_RAWBLOCK_PORT
# Enable publishing of raw transaction.
zmqpubrawtx=tcp://*:$ZMQ_RAWTR_PORT

txindex=1
deprecatedrpc=create_bdb

# Fallback fee
fallbackfee=0.00001

# Allow all IPs to access the RPC server.
[${NETWORK_LABEL}]
rpcbind=0.0.0.0
rpcallowip=0.0.0.0/0
rpcport=$RPC_PORT
EOF

echo "Starting bitcoind..."
bitcoind -${NETWORK} -datadir="$DATA_DIR" -conf="$CONF" -rpcport="$RPC_PORT" -daemon

# Allow some time for bitcoind to start
sleep 5

if [[ "$NETWORK" == "regtest" ]]; then
  if [[ ! -d "${DATA_DIR}/${NETWORK}/wallets/${WALLET_NAME}" ]]; then
    echo "Creating a wallet..."
    bitcoin-cli -${NETWORK} -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" createwallet "$WALLET_NAME" false false "$WALLET_PASS" false false
  fi

  echo "Opening ${WALLET_NAME} wallet..."
  bitcoin-cli -${NETWORK} -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$WALLET_NAME" walletpassphrase "$WALLET_PASS" 10

  echo "Generating 110 blocks for the first coinbases to mature..."
  bitcoin-cli -${NETWORK} -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$WALLET_NAME" -generate 110
fi

if [[ ! -d "${DATA_DIR}/${NETWORK}/wallets/${BTCSTAKER_WALLET_NAME}" ]]; then
  echo "Creating a wallet for btcstaker..."
  bitcoin-cli -${NETWORK} -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" createwallet "$BTCSTAKER_WALLET_NAME" false false "$WALLET_PASS" false false
fi

echo "Opening ${BTCSTAKER_WALLET_NAME} wallet..."
bitcoin-cli -${NETWORK} -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$BTCSTAKER_WALLET_NAME" walletpassphrase "$WALLET_PASS" 10
echo "Importing the private key to the wallet ${BTCSTAKER_WALLET_NAME} with the label ${BTCSTAKER_WALLET_NAME} without rescan..."
bitcoin-cli -${NETWORK} -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$BTCSTAKER_WALLET_NAME" importprivkey "$BTCSTAKER_PRIVKEY" "${BTCSTAKER_WALLET_NAME}" false

# Allow some time for the wallet to catch up.
sleep 5

if [[ "$NETWORK" == "regtest" ]]; then
  echo "Checking balance..."
  bitcoin-cli -${NETWORK} -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$WALLET_NAME" getbalance
  
  echo "Getting the imported BTC address for wallet ${BTCSTAKER_WALLET_NAME}..."
  BTCSTAKER_ADDR=$(bitcoin-cli -${NETWORK} -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$BTCSTAKER_WALLET_NAME" getaddressesbylabel "${BTCSTAKER_WALLET_NAME}" | jq -r 'keys[0]')
  echo "Imported BTC address: ${BTCSTAKER_ADDR}"

  echo "Generating a block every ${GENERATE_INTERVAL_SECS} seconds."
  while true; do
    bitcoin-cli -${NETWORK} -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$WALLET_NAME" -generate 1
    echo "Periodically send funds to the address ${BTCSTAKER_ADDR} for wallet ${BTCSTAKER_WALLET_NAME}..."
    bitcoin-cli -${NETWORK} -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$WALLET_NAME" walletpassphrase "$WALLET_PASS" 10
    bitcoin-cli -${NETWORK} -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$WALLET_NAME" sendtoaddress "$BTCSTAKER_ADDR" 10
    sleep "${GENERATE_INTERVAL_SECS}"
  done
elif [[ "$NETWORK" == "signet" ]]; then
  # Keep the container running
  echo "Bitcoind is running..."
  tail -f /dev/null
fi
