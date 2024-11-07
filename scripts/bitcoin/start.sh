#!/bin/bash
set -euo pipefail

# Load environment variables from .env.bitcoin file
set -a
source "$(pwd)/.env.bitcoin"
set +a
RPC_USER=snapchain

# Start the bitcoin container
echo "Starting the bitcoin container..."
docker compose -f "$(pwd)/docker/docker-compose-bitcoin.yml" up -d

# Wait for the bitcoin node to be ready
echo "Waiting for the bitcoin node to be ready..."
sleep 5

max_attempts=10
attempt=0
while ! docker exec bitcoind bitcoin-cli -${NETWORK} -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" getblockchaininfo &>/dev/null; do
    sleep 2
    ((attempt++))
    if [ $attempt -ge $max_attempts ]; then
        echo "Timeout waiting for bitcoin node to be ready."
        exit 1
    fi
done

echo "Bitcoin node is ready!"
echo

# Setup the wallet
echo "Setting up the wallet..."
docker exec -it bitcoind /setup-wallet.sh
echo "Wallet setup done!"
echo