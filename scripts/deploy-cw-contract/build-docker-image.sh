#!/bin/bash
set -euo pipefail

# Load environment variables
set -a
source $(pwd)/.env.deploy-cw-contract
set +a

DOCKERFILE_PATH=$(pwd)/scripts/deploy-cw-contract/Dockerfile
DOCKER_BUILD_PATH=$(pwd)/scripts/deploy-cw-contract
echo "Building deploy-cw-contract image..."
docker build --build-arg VERSION="${BABYLOND_VERSION}" --tag snapchain/deploy-cw-contract:latest -f ${DOCKERFILE_PATH} ${DOCKER_BUILD_PATH}
echo