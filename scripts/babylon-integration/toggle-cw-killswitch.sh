#!/bin/bash
set -euo pipefail

if [ -z "${IS_ENABLED:-}" ]; then
    echo "Error: ENABLE parameter is required"
    echo "Usage: make toggle-cw-killswitch ENABLE=true|false"
    exit 1
fi

sed -i.bak "s|\${IS_ENABLED}|$IS_ENABLED|g" .env.babylon-integration
rm .env.babylon-integration.bak

# setting the finality contract enabled value
docker compose -f docker/docker-compose-babylon-integration.yml up -d toggle-cw-killswitch
docker logs -f toggle-cw-killswitch