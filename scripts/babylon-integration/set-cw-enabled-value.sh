#!/bin/bash
set -euo pipefail

# setting the finality contract enabled value
docker compose -f docker/docker-compose-babylon-integration.yml up -d set-cw-enabled-value
docker logs -f set-cw-enabled-value