#!/bin/bash
set -euo pipefail

echo "Stopping btc-staker..."
docker compose -f docker/docker-compose-babylon-integration.yml down btc-staker

echo "Removing btc-staker directory..."
rm -rf ${pwd}/.btc-staker

echo "Stopped btc-staker"
echo