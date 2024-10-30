#!/bin/bash
set -euo pipefail

CONTRACT_DIR=$(pwd)/.contract
CONTRACT_ADDR_FILE=$(pwd)/.contract/contract-address.txt

# Only run if the directory does not exist
if [ ! -d "$CONTRACT_DIR" ]; then
  echo "Creating $CONTRACT_DIR directory..."
  mkdir -p $CONTRACT_DIR
fi

# deploy the contract
docker compose -f docker/docker-compose-babylon-integration.yml up -d deploy-cw-contract
docker logs -f deploy-cw-contract