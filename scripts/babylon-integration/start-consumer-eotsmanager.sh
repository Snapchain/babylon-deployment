#!/bin/bash
set -euo pipefail

# Load environment variables
set -a
source $(pwd)/.env.babylon-integration
set +a

EXAMPLE_EOTS_MANAGER_CONF=$(pwd)/configs/babylon-integration/consumer-eotsd.conf
CONSUMER_EOTS_MANAGER_DIR=$(pwd)/.consumer-eotsmanager
EOTS_MANAGER_CONF=$(pwd)/.consumer-eotsmanager/eotsd.conf

# Only run if the directory does not exist
if [ ! -d "$CONSUMER_EOTS_MANAGER_DIR" ]; then
  echo "Creating $CONSUMER_EOTS_MANAGER_DIR directory..."
  mkdir -p $CONSUMER_EOTS_MANAGER_DIR
  echo "Copying $EXAMPLE_EOTS_MANAGER_CONF to $EOTS_MANAGER_CONF..."
  cp $EXAMPLE_EOTS_MANAGER_CONF $EOTS_MANAGER_CONF

  # the folders are owned by user snapchain. but per https://github.com/babylonlabs-io/finality-provider/blob/c02f046587db569d550f63ed776ba05735728b01/Dockerfile#L40,
  # it needs to be writable by user 1138. so we need the permission.
  chmod -R 666 $CONSUMER_EOTS_MANAGER_DIR
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