#!/bin/bash
set -euo pipefail

# Load environment variables
set -a
source $(pwd)/.env.babylon-integration
set +a

CONSUMER_EOTS_MANAGER_DIR=$(pwd)/.consumer-eotsmanager
EXAMPLE_CONFIG=$(pwd)/configs/babylon-integration/consumer-eotsd.conf
EOTS_MANAGER_CONF=$(pwd)/.consumer-eotsmanager/eotsd.conf

# Only run if the directory does not exist
if [ ! -d "$CONSUMER_EOTS_MANAGER_DIR" ]; then
  echo "Creating $CONSUMER_EOTS_MANAGER_DIR directory..."
  mkdir -p $CONSUMER_EOTS_MANAGER_DIR
  echo "Copying $EXAMPLE_CONFIG to $EOTS_MANAGER_CONF..."
  cp $EXAMPLE_CONFIG $EOTS_MANAGER_CONF


  # TODO: 777 grants full read, write, and execute permissions to everyone 
  # (owner, group, and others). This is not a good idea for production use
  chmod -R 777 $CONSUMER_EOTS_MANAGER_DIR
  echo "Successfully initialized $CONSUMER_EOTS_MANAGER_DIR directory"
  echo
fi