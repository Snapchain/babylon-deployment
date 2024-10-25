#!/bin/bash
set -euo pipefail

# Load environment variables
set -a
source $(pwd)/.env.babylon-integration
set +a

echo "Stopping finality explorer..."
docker compose -f docker/docker-compose-babylon-integration.yml down -v finality-explorer

echo "Successfully stopped finality explorer"
