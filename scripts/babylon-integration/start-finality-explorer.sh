#!/bin/bash
set -euo pipefail

echo "Starting finality explorer..."
docker compose -f docker/docker-compose-babylon-integration.yml up -d finality-explorer

echo "Successfully started finality explorer"