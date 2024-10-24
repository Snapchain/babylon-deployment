#!/bin/bash
set -euo pipefail

echo "Stopping finality-gadget..."
docker compose -f docker/docker-compose-babylon-integration.yml down finality-gadget

echo "Removing finality-gadget directory..."
rm -rf $(pwd)/.finality-gadget

echo "Stopped finality-gadget"
echo
