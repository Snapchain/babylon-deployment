#!/bin/bash
set -euo pipefail

# Load environment variables
set -a
source $(pwd)/.env.babylon-integration
set +a

BABYLOND_PATH=$HOME/babylond
if [ ! -f "$BABYLOND_PATH" ]; then
    # Download the babylond binary
    # TODO: use Babylon repo instead of Snapchain
    echo "Downloading babylond..."
    curl -SL "https://github.com/Snapchain/babylond/releases/download/$BABYLOND_VERSION/${BABYLOND_FILE}" -o "${BABYLOND_FILE}"

    # Verify the babylond binary exists
    if [ ! -f "$BABYLOND_FILE" ]; then
        echo "Error: babylond binary not found at $BABYLOND_FILE"
        exit 1
    fi
    mv $BABYLOND_FILE $BABYLOND_PATH
    # Make the babylond binary executable
    chmod +x $BABYLOND_PATH
    echo "Babylon version: $($BABYLOND_PATH version)"
    echo
fi