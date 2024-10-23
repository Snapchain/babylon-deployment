#!/bin/bash
set -euo pipefail

# Load environment variables
set -a
source $(pwd)/.env.babylon-integration
set +a

EOTS_MANAGER_CONF=$(pwd)/.consumer-eotsmanager/eotsd.conf

# Check if the eotsd.conf file exists
if [ ! -f "$EOTS_MANAGER_CONF" ]; then
  echo "Error: $EOTS_MANAGER_CONF does not exist"
  exit 1
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