#!/bin/bash
set -euo pipefail

echo "Stopping finality explorer..."
docker compose -f docker/docker-compose-babylon-integration.yml down -v finality-explorer

echo "Successfully stopped finality explorer"
