#!/bin/bash
set -euo pipefail

# Load environment variables
set -a
source $(pwd)/.env.babylon-integration
set +a

BABYLOND_PATH=/usr/local/bin/babylond
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
    sudo mv $BABYLOND_FILE $BABYLOND_PATH
    # Make the babylond binary executable
    sudo chmod +x $BABYLOND_PATH
    echo "Babylon version: $(babylond version)"
fi
echo

if ! babylond keys show $BABYLON_PREFUNDED_KEY --keyring-backend test &> /dev/null; then
    echo "Importing babylon prefunded key $BABYLON_PREFUNDED_KEY..."
    babylond keys add $BABYLON_PREFUNDED_KEY \
        --keyring-backend test \
        --recover <<< "$BABYLON_PREFUNDED_KEY_MNEMONIC"
    echo "Imported babylon prefunded key $BABYLON_PREFUNDED_KEY"
fi
echo