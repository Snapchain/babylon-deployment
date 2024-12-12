#!/bin/bash
set -euo pipefail

echo "Stopping consumer-finality-provider..."
docker compose -f docker/docker-compose-babylon-integration.yml down consumer-finality-provider

echo "Moving consumer-finality-provider directory..."
sudo mv $(pwd)/.consumer-finality-provider $(pwd)/.consumer-finality-provider-deprecated-$(date +%Y%m%d%H%M%S)

echo "Stopped consumer-finality-provider"
echo