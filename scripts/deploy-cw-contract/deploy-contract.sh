#!/bin/bash
curl -SLO https://github.com/babylonlabs-io/babylon-contract/releases/download/v0.10.0-rc.0/op_finality_gadget.wasm.zip
unzip op_finality_gadget.wasm.zip
CW_CONTRACT_PATH=$HOME/artifacts/op_finality_gadget.wasm
babylond tx wasm store $CW_CONTRACT_PATH --gas-prices 0.2ubbn --gas auto --gas-adjustment 1.3 --from $(babylond keys show -a snapchain --keyring-backend test) --chain-id euphrates-0.5.0 --node https://rpc-euphrates.devnet.babylonlabs.io --keyring-backend test -o json -y > deploy_out
sleep 5
CW_DEPLOY_TX_HASH=$(cat deploy_out | grep -o '"txhash":"[^"]*"' | cut -d'"' -f4)

echo "cw deploy tx hash: $CW_DEPLOY_TX_HASH"

while [ -z "$CODE" ];
do
    sleep 5
    echo "try query code..."
    CODE=$(babylond query tx $CW_DEPLOY_TX_HASH --chain-id euphrates-0.5.0 --node https://rpc-euphrates.devnet.babylonlabs.io -o json | jq -r '.events[] | select(.type == "store_code") | .attributes[] | select(.key == "code_id") | .value')
done
echo "code is $CODE"
CW_ADMIN=$(babylond keys show -a snapchain --keyring-backend test)
CONSUMER_ID=op-chain-70611411
INIT_MSG_JSON=$(printf '{"admin":"%s","consumer_id":"%s","is_enabled":true}' "$CW_ADMIN" "$CONSUMER_ID")
CW_LABEL=op_finality_gadget
#INSTANTIATE_OUT=$(babylond tx wasm instantiate $CODE $INIT_MSG_JSON --label $CW_LABEL --no-admin --gas-prices 0.2ubbn --gas auto --gas-adjustment 1.3 --from $(babylond keys show -a snapchain --keyring-backend test) --chain-id euphrates-0.5.0 --node https://rpc-euphrates.devnet.babylonlabs.io --keyring-backend test -o json -y)
while [ -z "$INSTANTIATE_OUT" ];
do
    sleep 5
    echo "try instantiate..."
    INSTANTIATE_OUT=$(babylond tx wasm instantiate $CODE $INIT_MSG_JSON --label $CW_LABEL --no-admin --gas-prices 0.2ubbn --gas auto --gas-adjustment 1.3 --from $(babylond keys show -a snapchain --keyring-backend test) --chain-id euphrates-0.5.0 --node https://rpc-euphrates.devnet.babylonlabs.io --keyring-backend test -o json -y)
done

babylond query wasm list-contract-by-code $CODE --chain-id euphrates-0.5.0 --node https://rpc-euphrates.devnet.babylonlabs.io > instantiate_out
CONTRACT_ADDR=$(grep -A1 "contracts:" instantiate_out | tail -n 1 | awk -F '-' '{print $2}' | sed 's/^ *//;s/ *$//')

while [ -z "$CONTRACT_ADDR" ];
do
    sleep 5
    echo "try query contract address..."
    babylond query wasm list-contract-by-code $CODE --chain-id euphrates-0.5.0 --node https://rpc-euphrates.devnet.babylonlabs.io > instantiate_out
    CONTRACT_ADDR=$(grep -A1 "contracts:" instantiate_out | tail -n 1 | awk -F '-' '{print $2}' | sed 's/^ *//;s/ *$//')
done


QUERY='{"config":{}}'
babylond query wasm contract-state smart $CONTRACT_ADDR "$QUERY" --chain-id euphrates-0.5.0 --node https://rpc-euphrates.devnet.babylonlabs.io -o json > query_out

queryConsumerId=$(cat query_out | grep -o '"consumer_id":"[^"]*"' | cut -d'"' -f4)

if [ -z "$queryConsumerId" ]; then
  echo "Failed to get consumer_id"
  exit 1
fi

echo "cw contract deployed..."