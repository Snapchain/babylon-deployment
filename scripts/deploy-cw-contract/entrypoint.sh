#!/bin/bash
set -euo pipefail

echo "Printing babylond version..."
babylond version
echo

# TODO: don't use test keyring backend in production
echo "Importing key $CW_CONTRACT_ADMIN_KEY..."
babylond keys add $CW_CONTRACT_ADMIN_KEY --recover --keyring-backend test <<< "$CW_CONTRACT_ADMIN_KEY_MNEMONIC"
echo "Key $CW_CONTRACT_ADMIN_KEY imported"
echo