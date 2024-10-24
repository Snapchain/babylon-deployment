#!/bin/bash
set -euo pipefail

# Load environment variables
set -a
source $(pwd)/.env.babylon-integration
set +a

EOTS_MANAGER_CONF=$(pwd)/.consumer-eotsmanager/eotsd.conf

# Only run if the directory does not exist
if [ ! -d "$CONSUMER_EOTS_MANAGER_DIR" ]; then
  echo "Creating $CONSUMER_EOTS_MANAGER_DIR directory..."
  mkdir -p $CONSUMER_EOTS_MANAGER_DIR
  echo "Copying $CONFIGS_DIR/consumer-eotsd.conf to $EOTS_MANAGER_CONF..."
  cp $CONFIGS_DIR/consumer-eotsd.conf $EOTS_MANAGER_CONF

  chmod -R 777 $CONSUMER_EOTS_MANAGER_DIR
  echo "Successfully initialized $CONSUMER_EOTS_MANAGER_DIR directory"
  echo
fi

echo "Starting consumer-eotsmanager..."
docker compose -f docker/docker-compose-babylon-integration.yml up -d consumer-eotsmanager

echo "Waiting for consumer-eotsmanager to start..."
sleep 5
echo "Checking the docker logs for consumer-eotsmanager..."
# TODO: This is a hardcoded check to verify if eotsmanager has started successfully.
# We should find a better way to check if the service has started successfully.
REQUIRED_LOG_MESSAGE="EOTS Manager Daemon is fully active"
if ! docker compose -f docker/docker-compose-babylon-integration.yml logs consumer-eotsmanager | grep -q "$REQUIRED_LOG_MESSAGE"; then
    echo "Error: consumer-eotsmanager failed to start"
    exit 1
fi
echo "Successfully started consumer-eotsmanager"
echo