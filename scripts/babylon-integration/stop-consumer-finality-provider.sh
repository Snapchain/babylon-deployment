#!/bin/bash
set -euo pipefail

echo "Stopping consumer-finality-provider..."
docker compose -f docker/docker-compose-babylon-integration.yml down consumer-finality-provider

echo "Removing consumer-finality-provider directory..."
sudo rm -rf $(pwd)/.consumer-finality-provider

echo "Stopped consumer-finality-provider"
echo