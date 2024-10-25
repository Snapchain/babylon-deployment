#!/bin/bash
set -euo pipefail

# Load environment variables
set -a
source $(pwd)/.env.babylon-integration
set +a

echo "Starting finality explorer..."
docker compose -f docker/docker-compose-babylon-integration.yml up -d finality-explorer

echo "Successfully started finality explorer"