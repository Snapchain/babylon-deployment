#!/bin/bash
set -uo pipefail

# Function to handle pending transactions
wait_for_tx() {
    local tx_hash=$1
    local max_attempts=$2
    local interval=$3
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        # Query with explicit error handling
        if output=$(babylond query tx "$tx_hash" \
            --chain-id "$BABYLON_CHAIN_ID" \
            --node "$BABYLON_RPC_URL" -o json 2>&1); then
            echo "Transaction found"
            return 0
        else
            # Command failed, check if it's because tx is pending
            if echo "$output" | grep -q "Internal error: tx ($tx_hash) not found"; then
                echo "Transaction pending..."
                sleep "$interval"
                ((attempt++))
                continue
            fi
            # Other error occurred
            echo "Query failed: $output"
            return 1
        fi
    done
    
    echo "Timeout after $max_attempts attempts waiting for transaction $tx_hash to be available."
    return 1
}