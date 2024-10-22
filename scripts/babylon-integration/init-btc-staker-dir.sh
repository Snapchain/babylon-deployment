#!/bin/bash
set -euo pipefail

# Load environment variables
set -a
source $(pwd)/.env.babylon-integration
set +a

BTC_STAKER_DIR=$(pwd)/.btc-staker
CONFIGS_DIR=$(pwd)/configs/babylon-integration
BTC_STAKER_CONF=$(pwd)/.btc-staker/stakerd.conf

# Only run if the directory does not exist
if [ ! -d "$BTC_STAKER_DIR" ]; then
  echo "Creating $BTC_STAKER_DIR directory..."
  mkdir -p $BTC_STAKER_DIR
  
  # for btc-staker, replace placeholders with env variables
  cp $CONFIGS_DIR/stakerd.conf $BTC_STAKER_CONF
  sed -i.bak "s|\${BTC_WALLET_NAME}|$BTC_WALLET_NAME|g" $BTC_STAKER_CONF
  sed -i.bak "s|\${BTC_WALLET_PASS}|$BTC_WALLET_PASS|g" $BTC_STAKER_CONF
  sed -i.bak "s|\${BITCOIN_RPC_HOST}|$BITCOIN_RPC_HOST|g" $BTC_STAKER_CONF
  sed -i.bak "s|\${BITCOIN_RPC_USER}|$BITCOIN_RPC_USER|g" $BTC_STAKER_CONF
  sed -i.bak "s|\${BITCOIN_RPC_PASS}|$BITCOIN_RPC_PASS|g" $BTC_STAKER_CONF
  sed -i.bak "s|\${BITCOIN_NETWORK}|$BITCOIN_NETWORK|g" $BTC_STAKER_CONF
  sed -i.bak "s|\${ZMQ_RAWBLOCK_URL}|$ZMQ_RAWBLOCK_URL|g" $BTC_STAKER_CONF
  sed -i.bak "s|\${ZMQ_RAWTR_URL}|$ZMQ_RAWTR_URL|g" $BTC_STAKER_CONF
  sed -i.bak "s|\${BTC_STAKER_KEY}|$BTC_STAKER_KEY|g" $BTC_STAKER_CONF
  sed -i.bak "s|\${BABYLON_CHAIN_ID}|$BABYLON_CHAIN_ID|g" $BTC_STAKER_CONF
  sed -i.bak "s|\${BABYLON_RPC_URL}|$BABYLON_RPC_URL|g" $BTC_STAKER_CONF
  sed -i.bak "s|\${BABYLON_GRPC_URL}|$BABYLON_GRPC_URL|g" $BTC_STAKER_CONF
  rm $BTC_STAKER_DIR/stakerd.conf.bak
  echo "Successfully updated the conf file $BTC_STAKER_CONF"

  # Check if the default keyring exists
  DEFAULT_KEY_FILE=${HOME}/.babylond/keyring-test/${BTC_STAKER_KEY}.info
  if [ ! -f $DEFAULT_KEY_FILE ]; then
    # echo "Creating default keyring..."
    # babylond keys add ${BTC_STAKER_KEY} --recover --keyring-backend test
    echo "No default keyring found in $DEFAULT_KEY_FILE"
    exit 1
  fi

  # Copy the btc-staker key to the testnet directory
  cp -R $HOME/.babylond/keyring-test $BTC_STAKER_DIR/

  chmod -R 777 $BTC_STAKER_DIR
  echo "Successfully initialized $BTC_STAKER_DIR directory"
  echo
fi