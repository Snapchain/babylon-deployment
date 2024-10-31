#!/bin/bash
set -euo pipefail

# Load environment variables
set -a
source $(pwd)/.env.babylon-integration
set +a

EXAMPLE_FINALITY_GADGET_CONF=$(pwd)/configs/babylon-integration/opfgd.toml
FINALITY_GADGET_DIR=$(pwd)/.finality-gadget
FINALITY_GADGET_CONF=$(pwd)/.finality-gadget/opfgd.toml

if [ ! -d "$FINALITY_GADGET_DIR" ]; then
  echo "Creating $FINALITY_GADGET_DIR directory..."
  mkdir -p $FINALITY_GADGET_DIR

  echo "Copying $EXAMPLE_FINALITY_GADGET_CONF to $FINALITY_GADGET_CONF..."
  cp $EXAMPLE_FINALITY_GADGET_CONF $FINALITY_GADGET_CONF

  # Update the config file with environment variables
  sed -i.bak "s|\${L2_RPC_URL}|$L2_RPC_URL|g" $FINALITY_GADGET_CONF
  sed -i.bak "s|\${BITCOIN_RPC_HOST}|$BITCOIN_RPC_HOST|g" $FINALITY_GADGET_CONF
  sed -i.bak "s|\${BITCOIN_RPC_USER}|$BITCOIN_RPC_USER|g" $FINALITY_GADGET_CONF
  sed -i.bak "s|\${BITCOIN_RPC_PASS}|$BITCOIN_RPC_PASS|g" $FINALITY_GADGET_CONF
  sed -i.bak "s|\${FINALITY_GADGET_ADDRESS}|$FINALITY_GADGET_ADDRESS|g" $FINALITY_GADGET_CONF
  sed -i.bak "s|\${BABYLON_CHAIN_ID}|$BABYLON_CHAIN_ID|g" $FINALITY_GADGET_CONF
  sed -i.bak "s|\${BABYLON_RPC_URL}|$BABYLON_RPC_URL|g" $FINALITY_GADGET_CONF

  rm $FINALITY_GADGET_DIR/opfgd.toml.bak
  echo "Successfully updated the conf file $FINALITY_GADGET_CONF"
  # the folders are owned by user snapchain. but per https://github.com/babylonlabs-io/finality-gadget/blob/37a8b1c9b2698c9967bbc060583668d6c7a1e6f9/Dockerfile#L38,
  # it needs to be writable by user 1138. so we need the permission.
  chmod -R 777 $FINALITY_GADGET_DIR
  echo "Successfully initialized $FINALITY_GADGET_DIR directory"
  echo
fi

echo "Starting finality-gadget..."
docker compose -f docker/docker-compose-babylon-integration.yml up -d finality-gadget

echo "Waiting for finality-gadget to start..."
sleep 10