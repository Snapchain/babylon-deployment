#!/bin/bash

###############################################################################################
# 2. Start EOTS manager                                                                       #
# ------------------------------------------------------------------------------------------- #
# This script starts the `eotsmanager` service.                                               #
###############################################################################################

set -euo pipefail

# Load environment variables
if [ ! -f $(pwd)/.env.babylon ]; then
    echo "Error: .env.babylon file not found"
    echo "Run `cp .env.babylon.example .env.babylon` and set the variables"
    exit 1
fi
set -a
source $(pwd)/.env.babylon
set +a

# Start the `eotsmanager` service
docker compose -f docker/docker-compose-babylon.yml up -d eotsmanager