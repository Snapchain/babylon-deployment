#!/bin/bash
set -euo pipefail

# setting the finality contract enabled value
docker compose -f docker/docker-compose-babylon-integration.yml up -d toggle-cw-killswitch
docker logs -f toggle-cw-killswitch