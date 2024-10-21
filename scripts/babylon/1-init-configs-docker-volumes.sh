#!/bin/bash

###############################################################################################
# 1. Initialize config files and Docker data volumes                                          #
# ------------------------------------------------------------------------------------------- #
# This script initializes configuration files and data directories for the Docker containers  #
# in a local `.testnets` directory, which is later mounted into the containers at runtime.    #
# It should be run before running any `docker compose` commands.                              #
###############################################################################################

set -euo pipefail

# Load environment variables
if [ ! -f $(pwd)/.env.babylon ]; then
    echo "Error: .env.babylon file not found"
    echo "Run `cp .env.babylon.example .env.babylon` and set the variables"
    exit 1
fi
set -a
source $(pwd)/.env.babylon
set +a

# Create new directory that will hold Docker configuration and data
mkdir -p .testnets

# Set permissions for the new directory
sudo chown -R $(whoami):$(whoami) .testnets
sudo chmod -R 777 .testnets

# Create separate subpaths for each component and copy relevant configuration
mkdir -p .testnets/vigilante/bbnconfig
mkdir -p .testnets/btc-staker
mkdir -p .testnets/eotsmanager
mkdir -p .testnets/finality-provider
mkdir -p .testnets/covenant-emulator
mkdir -p .testnets/node0/babylond/covenant-emulator/keyring-test

# Copy over `stakerd.conf` for `btc-staker`, replacing placeholders with env variables
cp config/babylon/stakerd.conf .testnets/btc-staker/stakerd.conf
sed -i.bak "s|\${BITCOIN_NETWORK}|$BITCOIN_NETWORK|g" .testnets/btc-staker/stakerd.conf
sed -i.bak "s|\${BITCOIN_RPC_PORT}|$BITCOIN_RPC_PORT|g" .testnets/btc-staker/stakerd.conf
sed -i.bak "s|\${WALLET_PASS}|$WALLET_PASS|g" .testnets/btc-staker/stakerd.conf
sed -i.bak "s|\${BABYLON_CHAIN_ID}|$BABYLON_CHAIN_ID|g" .testnets/btc-staker/stakerd.conf
rm .testnets/btc-staker/stakerd.conf.bak

# Copy over `vigilante.yml` for `vigilante` services, replacing placeholders with env variables
cp config/babylon/vigilante.yml .testnets/vigilante/vigilante.yml
sed -i.bak "s|\${BITCOIN_NETWORK}|$BITCOIN_NETWORK|g" .testnets/vigilante/vigilante.yml
sed -i.bak "s|\${BITCOIN_RPC_PORT}|$BITCOIN_RPC_PORT|g" .testnets/vigilante/vigilante.yml
sed -i.bak "s|\${WALLET_PASS}|$WALLET_PASS|g" .testnets/vigilante/vigilante.yml
rm .testnets/vigilante/vigilante.yml.bak

# Copy over `covd.conf` for `covenant-emulator`, replacing placeholders with env variables
cp config/babylon/covd.conf .testnets/covenant-emulator/covd.conf
sed -i.bak "s|\${BITCOIN_NETWORK}|$BITCOIN_NETWORK|g" .testnets/covenant-emulator/covd.conf
rm .testnets/covenant-emulator/covd.conf.bak

# Copy over `covenant-keyring` to `.testnets/covenant-emulator/keyring-test`
# TODO: disabled for now, we need to first check how this keyring data is generated and document it properly
# cp -R artifacts/covenant-keyring .testnets/covenant-emulator/keyring-test

echo "Successfully initialized Docker data directory"