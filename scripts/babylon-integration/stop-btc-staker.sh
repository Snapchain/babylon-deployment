#!/bin/bash
set -euo pipefail

echo "Stopping btc-staker..."
docker compose -f docker/docker-compose-babylon-integration.yml down btc-staker

echo "Moving btc-staker directory..."
sudo mv $(pwd)/.btc-staker $(pwd)/.btc-staker-deprecated-$(date +%Y%m%d%H%M%S)

echo "Stopped btc-staker"
echo