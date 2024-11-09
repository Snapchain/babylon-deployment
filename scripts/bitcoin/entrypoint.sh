#!/bin/bash
set -euo pipefail

echo "NETWORK: $NETWORK"
echo "RPC_PORT: $RPC_PORT"

if [[ "$NETWORK" != "regtest" && "$NETWORK" != "signet" ]]; then
  echo "Unsupported network: $NETWORK"
  exit 1
fi

DATA_DIR=/bitcoind/.bitcoin
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
bitcoind -${NETWORK} -datadir="$DATA_DIR" -conf="$CONF" -rpcport="$RPC_PORT"