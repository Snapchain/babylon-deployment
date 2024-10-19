#!/bin/bash
set -euo pipefail

# Stop the bitcoin container
docker compose -f "$(pwd)/docker/docker-compose-bitcoin.yml" down

# Remove the bitcoin volume
docker volume ls --filter name=bitcoin_data --format='{{.Name}}' | xargs -r docker volume rm