#!/bin/bash
set -euo pipefail

# register the consumer chain
docker compose -f docker/docker-compose-babylon-integration.yml up -d register-consumer-chain
docker logs -f register-consumer-chain