#!/bin/bash
set -euo pipefail

# Load environment variables
set -a
source $(pwd)/.env.babylon-integration
set +a

EXAMPLE_FINALITY_PROVIDER_CONF=$(pwd)/configs/babylon-integration/consumer-fpd.conf
CONSUMER_FINALITY_PROVIDER_DIR=$(pwd)/.consumer-finality-provider
FINALITY_PROVIDER_CONF=$(pwd)/.consumer-finality-provider/fpd.conf

if [ ! -d "$CONSUMER_FINALITY_PROVIDER_DIR" ]; then
  echo "Creating $CONSUMER_FINALITY_PROVIDER_DIR directory..."
  mkdir -p $CONSUMER_FINALITY_PROVIDER_DIR

  echo "Copying $EXAMPLE_FINALITY_PROVIDER_CONF to $FINALITY_PROVIDER_CONF..."
  cp $EXAMPLE_FINALITY_PROVIDER_CONF $FINALITY_PROVIDER_CONF

  # for finality provider, replace placeholders with env variables
  sed -i.bak "s|\${CONSUMER_EOTS_MANAGER_ADDRESS}|$CONSUMER_EOTS_MANAGER_ADDRESS|g" $FINALITY_PROVIDER_CONF
  sed -i.bak "s|\${BITCOIN_NETWORK}|$BITCOIN_NETWORK|g" $FINALITY_PROVIDER_CONF
  sed -i.bak "s|\${CONSUMER_FINALITY_PROVIDER_KEY}|$CONSUMER_FINALITY_PROVIDER_KEY|g" $FINALITY_PROVIDER_CONF
  sed -i.bak "s|\${L2_RPC_URL}|$L2_RPC_URL|g" $FINALITY_PROVIDER_CONF
  sed -i.bak "s|\${FINALITY_GADGET_RPC}|$FINALITY_GADGET_RPC|g" $FINALITY_PROVIDER_CONF
  sed -i.bak "s|\${FINALITY_GADGET_ADDRESS}|$FINALITY_GADGET_ADDRESS|g" $FINALITY_PROVIDER_CONF
  sed -i.bak "s|\${BABYLON_CHAIN_ID}|$BABYLON_CHAIN_ID|g" $FINALITY_PROVIDER_CONF
  sed -i.bak "s|\${BABYLON_RPC_URL}|$BABYLON_RPC_URL|g" $FINALITY_PROVIDER_CONF
  sed -i.bak "s|\${BABYLON_GRPC_URL}|$BABYLON_GRPC_URL|g" $FINALITY_PROVIDER_CONF
  rm $CONSUMER_FINALITY_PROVIDER_DIR/fpd.conf.bak
  echo "Successfully updated the conf file $FINALITY_PROVIDER_CONF"

  # Create new Babylon account for the finality provider
  CONSUMER_FP_KEYRING_DIR=${HOME}/.babylond/${CONSUMER_FINALITY_PROVIDER_KEY}
  if ! babylond keys show $CONSUMER_FINALITY_PROVIDER_KEY --keyring-dir $CONSUMER_FP_KEYRING_DIR --keyring-backend test &> /dev/null; then
      echo "Creating keyring directory $CONSUMER_FP_KEYRING_DIR"
      mkdir -p $CONSUMER_FP_KEYRING_DIR
      echo "Creating key $CONSUMER_FINALITY_PROVIDER_KEY..."
      babylond keys add $CONSUMER_FINALITY_PROVIDER_KEY \
          --keyring-backend test \
          --keyring-dir $CONSUMER_FP_KEYRING_DIR \
          --output json > $CONSUMER_FINALITY_PROVIDER_DIR/${CONSUMER_FINALITY_PROVIDER_KEY}.json
      echo "Generated consumer-finality-provider key $CONSUMER_FINALITY_PROVIDER_KEY"
  fi
  echo
  CONSUMER_FP_ADDRESS=$(babylond keys show $CONSUMER_FINALITY_PROVIDER_KEY --keyring-backend test --keyring-dir $CONSUMER_FP_KEYRING_DIR --output json | jq -r '.address')

  # Copy the finality provider key to the mounted .consumer-finality-provider directory
  cp -R $CONSUMER_FP_KEYRING_DIR/keyring-test $CONSUMER_FINALITY_PROVIDER_DIR/
  echo "Copied the generated key to the $CONSUMER_FINALITY_PROVIDER_DIR directory"

  chmod -R 777 $CONSUMER_FINALITY_PROVIDER_DIR
  echo "Successfully initialized $CONSUMER_FINALITY_PROVIDER_DIR directory"
  echo
fi

# check the balance of the babylon prefunded key
echo "Checking the balance of the babylon prefunded key $BABYLON_PREFUNDED_KEY..."
PREFUNDED_ADDRESS=$(babylond keys show $BABYLON_PREFUNDED_KEY --keyring-backend test --output json | jq -r '.address')
BABYLON_PREFUNDED_KEY_BALANCE=$(babylond query bank balances ${PREFUNDED_ADDRESS} \
    --chain-id $BABYLON_CHAIN_ID \
    --node $BABYLON_RPC_URL \
    --output json | jq -r '.balances[0].amount')
if [ $BABYLON_PREFUNDED_KEY_BALANCE -lt $CONSUMER_FP_FUND_AMOUNT ]; then
    echo "Babylon prefunded key balance is less than the funding amount"
    exit 1
fi
echo "Babylon prefunded key balance: $BABYLON_PREFUNDED_KEY_BALANCE"

# fund the consumer-finality-provider account
echo "Funding account $CONSUMER_FINALITY_PROVIDER_KEY..."
FUND_TX_HASH=$(babylond tx bank send \
    ${PREFUNDED_ADDRESS} \
    ${CONSUMER_FP_ADDRESS} \
    "${CONSUMER_FP_FUND_AMOUNT}ubbn" \
    --chain-id $BABYLON_CHAIN_ID \
    --node $BABYLON_RPC_URL \
    --keyring-backend test \
    --gas auto \
    --gas-adjustment 1.5 \
    --gas-prices 0.2ubbn \
    --output json -y \
    | jq -r '.txhash')
echo "Funding transaction hash: $FUND_TX_HASH"

echo "Starting consumer-finality-provider..."
docker compose -f docker/docker-compose-babylon-integration.yml up -d consumer-finality-provider

echo "Waiting for consumer-finality-provider to start..."
sleep 10

max_attempts=5
attempt=0
while ! docker exec consumer-finality-provider fpd list-finality-providers &>/dev/null; do
    sleep 2
    ((attempt++))
    if [ $attempt -ge $max_attempts ]; then
        echo "Timeout waiting for consumer-finality-provider to be ready."
        exit 1
    fi
done

echo "Successfully started consumer-finality-provider"
echo