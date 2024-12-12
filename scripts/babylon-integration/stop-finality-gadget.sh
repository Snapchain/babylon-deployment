#!/bin/bash
set -euo pipefail

echo "Stopping finality-gadget..."
docker compose -f docker/docker-compose-babylon-integration.yml down finality-gadget

echo "Moving finality-gadget directory..."
sudo mv $(pwd)/.finality-gadget $(pwd)/.finality-gadget-deprecated-$(date +%Y%m%d%H%M%S)

echo "Stopped finality-gadget"
echo
