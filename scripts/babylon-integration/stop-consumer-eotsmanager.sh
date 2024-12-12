#!/bin/bash
set -euo pipefail

echo "Stopping consumer-eotsmanager..."
docker compose -f docker/docker-compose-babylon-integration.yml down consumer-eotsmanager

echo "Moving consumer-eotsmanager directory..."
sudo mv $(pwd)/.consumer-eotsmanager $(pwd)/.consumer-eotsmanager-deprecated-$(date +%Y%m%d%H%M%S)

echo "Stopped consumer-eotsmanager"
echo