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
    curl -SL "https://github.com/Snapchain/babylond/releases/download/$BABYLOND_VERSION/${BABYLOND_FILE}" \
        -o "${BABYLOND_FILE}"

    # Verify the babylond binary exists
    if [ ! -f "$BABYLOND_FILE" ]; then
        echo "Error: babylond binary not found at $BABYLOND_FILE"
        exit 1
    fi
    sudo mv $BABYLOND_FILE $BABYLOND_PATH
    # Make the babylond binary executable
    sudo chmod +x $BABYLOND_PATH
fi
echo

# Install libraries
# Cosmwasm - Download correct libwasmvm version
echo "Installing libwasmvm library for babylond..."
curl -SL "https://raw.githubusercontent.com/babylonlabs-io/babylon/refs/tags/$BABYLOND_VERSION/go.mod" \
    -o /tmp/go.mod
WASMVM_VERSION=$(grep github.com/CosmWasm/wasmvm /tmp/go.mod | cut -d' ' -f2)
ARCH=$(uname -m)
LIBFILE="libwasmvm.${ARCH}.so"
sudo curl -SL "https://github.com/CosmWasm/wasmvm/releases/download/$WASMVM_VERSION/$LIBFILE" \
    -o "/lib/$LIBFILE"
# Download and verify checksum
curl -SL "https://github.com/CosmWasm/wasmvm/releases/download/$WASMVM_VERSION/checksums.txt" \
    -o /tmp/checksums.txt
EXPECTED_CHECKSUM=$(grep "$LIBFILE" /tmp/checksums.txt | cut -d ' ' -f 1)
ACTUAL_CHECKSUM=$(sha256sum "/lib/$LIBFILE" | cut -d ' ' -f 1)
if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
    echo "Checksum verification failed"
    exit 1
fi
rm -f /tmp/go.mod /tmp/checksums.txt
echo

# Check babylond version
echo "Babylon version: $(babylond version)"
echo

if ! babylond keys show $BABYLON_PREFUNDED_KEY --keyring-backend test &> /dev/null; then
    echo "Importing babylon prefunded key $BABYLON_PREFUNDED_KEY..."
    babylond keys add $BABYLON_PREFUNDED_KEY \
        --keyring-backend test \
        --recover <<< "$BABYLON_PREFUNDED_KEY_MNEMONIC"
    echo "Imported babylon prefunded key $BABYLON_PREFUNDED_KEY"
fi
echo