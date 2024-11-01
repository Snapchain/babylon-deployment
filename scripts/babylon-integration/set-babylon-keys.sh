#!/bin/bash
set -euo pipefail

DEPLOY_OUTPUT_DIR=$(pwd)/.deploy

# Only run if the directory does not exist
if [ ! -d "$DEPLOY_OUTPUT_DIR" ]; then
  echo "Creating $DEPLOY_OUTPUT_DIR directory..."
  mkdir -p $DEPLOY_OUTPUT_DIR
fi

# set the babylon keys
docker compose -f docker/docker-compose-babylon-integration.yml up -d set-babylon-keys
docker logs -f set-babylon-keys