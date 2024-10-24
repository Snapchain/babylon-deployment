#!/bin/bash
set -euo pipefail

# For signet, load environment variables from .env file
set -a
source $(pwd)/.env
set +a

if [ -z "$(echo ${STAKING_TIME})" ] || [ -z "$(echo ${STAKING_AMOUNT})" ]; then
    echo "Error: STAKING_TIME or STAKING_AMOUNT environment variable is not set"
    exit 1
fi
echo "Environment variables loaded successfully"
echo

# Create BTC delegation to the finality providers
echo "Create BTC delegation to Babylon and OP consumer finality providers from a dedicated BTC address"
DELEGATION_ADDR=$(docker exec btc-staker \
    /bin/sh -c "/bin/stakercli daemon list-outputs" \
    | jq -r '.outputs[].address' | sort | uniq)
BBN_FP_BTC_PK=$(docker exec btc-staker \
    /bin/sh -c "/bin/stakercli daemon babylon-finality-providers" \
    | jq -r '.finality_providers[].bitcoin_public_Key' | shuf -n 1)
OP_FP_BTC_PK=$(docker exec consumer-finality-provider \
    /bin/sh -c "/bin/fpd list-finality-providers" \
    | jq -r '.finality_providers[].btc_pk_hex' | shuf -n 1)

echo "Delegating $STAKING_AMOUNT Satoshis from BTC address $DELEGATION_ADDR to Babylon finality provider $BBN_FP_BTC_PK and OP consumer finality provider $OP_FP_BTC_PK for $STAKING_TIME BTC blocks"
BTC_DEL_TX_HASH=$(docker exec btc-staker /bin/sh \
    -c "/bin/stakercli daemon stake \
    --staker-address $DELEGATION_ADDR \
    --staking-amount $STAKING_AMOUNT \
    --finality-providers-pks $BBN_FP_BTC_PK \
    --finality-providers-pks $OP_FP_BTC_PK \
    --staking-time $STAKING_TIME" \
    | jq -r '.tx_hash')
echo "Delegation was successful; staking tx hash is $BTC_DEL_TX_HASH"
echo