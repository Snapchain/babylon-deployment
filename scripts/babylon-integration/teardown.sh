#!/bin/bash
set -euo pipefail

docker compose -f docker/docker-compose-babylon-integration.yml up -d teardown
docker logs -f teardown