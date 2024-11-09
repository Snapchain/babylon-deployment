#!/bin/bash
set -euo pipefail

# Load environment variables
set -a
source $(pwd)/.env.babylon-integration
set +a

EXAMPLE_BTC_STAKER_CONF=$(pwd)/configs/babylon-integration/stakerd.conf
BTC_STAKER_DIR=$(pwd)/.btc-staker
BTC_STAKER_CONF=$(pwd)/.btc-staker/stakerd.conf
PREFUNDED_KEYRING_DIR=$(pwd)/.deploy/babylond

# Only run if the directory does not exist
if [ ! -d "$BTC_STAKER_DIR" ]; then
  echo "Creating $BTC_STAKER_DIR directory..."
  mkdir -p $BTC_STAKER_DIR
  
  # for btc-staker, replace placeholders with env variables
  cp $EXAMPLE_BTC_STAKER_CONF $BTC_STAKER_CONF
  sed -i.bak "s|\${BTC_WALLET_NAME}|$BTC_WALLET_NAME|g" $BTC_STAKER_CONF
  sed -i.bak "s|\${BTC_WALLET_PASS}|$BTC_WALLET_PASS|g" $BTC_STAKER_CONF
  sed -i.bak "s|\${BITCOIN_RPC_HOST}|$BITCOIN_RPC_HOST|g" $BTC_STAKER_CONF
  sed -i.bak "s|\${BITCOIN_RPC_USER}|$BITCOIN_RPC_USER|g" $BTC_STAKER_CONF
  sed -i.bak "s|\${BITCOIN_RPC_PASS}|$BITCOIN_RPC_PASS|g" $BTC_STAKER_CONF
  sed -i.bak "s|\${BITCOIN_NETWORK}|$BITCOIN_NETWORK|g" $BTC_STAKER_CONF
  sed -i.bak "s|\${ZMQ_RAWBLOCK_URL}|$ZMQ_RAWBLOCK_URL|g" $BTC_STAKER_CONF
  sed -i.bak "s|\${ZMQ_RAWTR_URL}|$ZMQ_RAWTR_URL|g" $BTC_STAKER_CONF
  sed -i.bak "s|\${BTC_STAKER_KEY}|$BABYLON_PREFUNDED_KEY|g" $BTC_STAKER_CONF
  sed -i.bak "s|\${BABYLON_CHAIN_ID}|$BABYLON_CHAIN_ID|g" $BTC_STAKER_CONF
  sed -i.bak "s|\${BABYLON_RPC_URL}|$BABYLON_RPC_URL|g" $BTC_STAKER_CONF
  sed -i.bak "s|\${BABYLON_GRPC_URL}|$BABYLON_GRPC_URL|g" $BTC_STAKER_CONF
  rm $BTC_STAKER_DIR/stakerd.conf.bak
  echo "Successfully updated the conf file $BTC_STAKER_CONF"

  # Copy the prefunded key to the mounted .btc-staker directory
  cp -R $PREFUNDED_KEYRING_DIR/keyring-test $BTC_STAKER_DIR/
  echo "Copied the imported key to the $BTC_STAKER_DIR directory"

  # the folders are owned by user snapchain. but per https://github.com/babylonlabs-io/btc-staker/blob/6eb0a65145a472f209726dfe0b8fc0cfd6ab3068/Dockerfile#L22,
  # it needs to be writable by user 1138. so we need the permission.
  chmod -R 777 $BTC_STAKER_DIR
  echo "Successfully initialized $BTC_STAKER_DIR directory"
  echo
fi

echo "Starting btc-staker..."
docker compose -f docker/docker-compose-babylon-integration.yml up -d btc-staker

# Wait for the btc-staker to be ready
echo "Waiting for the btc-staker to be ready..."
sleep 10

max_attempts=5
attempt=0
while ! docker exec btc-staker stakercli daemon babylon-finality-providers &>/dev/null; do
    sleep 2
    ((attempt++))
    if [ $attempt -ge $max_attempts ]; then
        echo "Timeout waiting for btc-staker to be ready."
        exit 1
    fi
done

echo "Babylon btc-staker is ready!"
echo