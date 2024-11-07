#!/bin/bash
set -euo pipefail

# Load environment variables
set -a
source $(pwd)/.env.babylon-integration
set +a

# check if the OP consumer FP already exists
EXISTING_OP_FP_MONIKER=$(docker exec consumer-finality-provider /bin/sh \
    -c "/bin/fpd list-finality-providers" \
    | jq '.finality_providers[0].description.moniker')
EXISTING_OP_FP_EOTS_PK_HEX=$(docker exec consumer-finality-provider /bin/sh \
    -c "/bin/fpd list-finality-providers" \
    | jq -r '.finality_providers[0].btc_pk_hex')
if [ "$EXISTING_OP_FP_MONIKER" == "$OP_FP_MONIKER" ]; then
    echo "OP consumer finality provider already exists with \
moniker: $EXISTING_OP_FP_MONIKER and \
EOTS PK: $EXISTING_OP_FP_EOTS_PK_HEX"
    exit 0
fi

# create FP for the consumer chain
echo "Creating OP consumer finality provider..."
OP_FP_EOTS_PK_HEX=$(docker exec consumer-finality-provider /bin/sh \
    -c "/bin/fpd create-finality-provider \
    --key-name $CONSUMER_FINALITY_PROVIDER_KEY \
    --chain-id $CONSUMER_ID \
    --moniker \"$OP_FP_MONIKER\"" | jq -r '.btc_pk_hex')
echo "OP_FP_EOTS_PK_HEX: $OP_FP_EOTS_PK_HEX"
echo
sleep 5

echo "Registering OP consumer finality provider..."
OP_FP_REGISTRATION_TX_OUTPUT=$(docker exec consumer-finality-provider /bin/sh \
    -c "/bin/fpd register-finality-provider $OP_FP_EOTS_PK_HEX")
echo "OP consumer finality provider registration tx output: $OP_FP_REGISTRATION_TX_OUTPUT"
OP_FP_REGISTRATION_TX_HASH=$(echo "$OP_FP_REGISTRATION_TX_OUTPUT" | jq -r '.tx_hash')
echo "OP consumer finality provider registration tx hash: $OP_FP_REGISTRATION_TX_HASH"
echo