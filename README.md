# BTC Staking Integration for OP-Stack Chains

This guide describes how to integrate the Babylon Bitcoin Staking protocol to an OP-Stack chain.

It assumes you already have an OP-Stack chain deployed. If not, we recommend deploying an OP-Stack devnet using our [OP chain deployment](https://github.com/Snapchain/op-chain-deployment) repo.

It's recommended you skim through this guide before starting with the following steps.

## System Recommendations

The guide was tested on:

- a Debian 12 x64 machine on Digital Ocean
- 8GB Memory
- 160GB Disk

It's recommended you execute the following steps on a similar or better machine.

## Dependencies

The following dependencies are required on your machine.

| Dependency                                         | Version | Version Check Command    |
| -------------------------------------------------- | ------- | ------------------------ |
| [git](https://git-scm.com/)                        | ^2      | `git --version`          |
| [docker](https://www.docker.com/)                  | ^20     | `docker --version`       |
| [docker compose](https://docs.docker.com/compose/) | ^2.20   | `docker compose version` |
| [make](https://linux.die.net/man/1/make)           | ^3      | `make --version`         |
| [curl](https://curl.se/)                           | ^8      | `curl --version`         |
| [jq](https://github.com/jqlang/jq)                 | ^1.6    | `jq --version`           |

## Setup Bitcoin node

A Bitcoin node is required to run the Babylon BTC Staker program. You will need to import a private key with some BTC into the Bitcoin node. If you don't have one, you can generate a new account using OKX wallet and export the private key. To integrate with Babylon Euphrates 0.5.0 devnet, you need to use the Signet Bitcoin test network. You can get some signet BTC through faucets such as https://signetfaucet.com/.

1. Copy the `.env.bitcoin.example` file to `.env.bitcoin` and set the variables

   ```bash
   cp .env.bitcoin.example .env.bitcoin
   ```

   - For the Babylon Euphrates integration, the `NETWORK` variable should be set as `signet`.
   - The `BTC_PRIVKEY` variable must be a valid Bitcoin private key in WIF format.

2. Start the Bitcoin node

   ```bash
   make start-bitcoin
   ```

3. Verify the Bitcoin node is synced and has a balance

   ```bash
   make verify-bitcoin-sync-balance
   ```

   Note: this step may take ~10 minutes to complete.

If you want to check the Bitcoin node logs, you can run the following command:

```bash
docker compose -f docker/docker-compose-bitcoin.yml logs -f bitcoind
```

If you want to stop the Bitcoin node (and remove the synced data), you can run the following command:

```bash
make stop-bitcoin
```

## Upgrade OP-stack chain to support BTC staking

To integrate with Babylon, you will need to upgrade your nodes to support BTC staking. To do so, replace `op-node` with Snapchain's [fork](https://hub.docker.com/r/babylonlabs/op-node-babylon-finality-gadget), available as a Docker image.

If you are unsure how to do this, please refer to the [OP chain deployment](https://github.com/Snapchain/op-chain-deployment/blob/main/README.md) guide.

## Integrate Babylon finality system with OP-Stack chain

This section describes how to integrate the Babylon finality system to your OP-Stack chain, using Babylon Euphrates 0.5.0 devnet.

Before starting, please make sure:

- Your Bitcoin Signet node is synced and has a wallet with enough signet BTC balance (e.g. >0.01 BTC).
- Your OP-Stack chain is running and has at least one finalized block. This is important because the Babylon fast finality gadget starts processing blocks from the (non-zero) finalized height.

For more details about how to setup an OP-Stack chain with BTC staking support, please refer to the [OP chain deployment](https://github.com/Snapchain/op-chain-deployment/blob/main/README.md) repo.

### 1. Get some test BBN tokens from the Euphrates faucet

```bash
curl https://faucet-euphrates.devnet.babylonlabs.io/claim \
-H "Content-Type: multipart/form-data" \
-d '{ "address": "<YOUR_BABYLON_ADDRESS>"}'
```

### 2. Setup environment variables

Copy the `.env.babylon-integration.example` file to `.env.babylon-integration`

```bash
cp .env.babylon-integration.example .env.babylon-integration
```

The key env vars to set are the server IP addresses where your Bitcoin Signet node and Babylon finality system are deployed. Note that the ports are preconfigured in the Docker Compose files used for this deployment.

- `BITCOIN_RPC_HOST`: the Bitcoin Signet node's IP address.
- `ZMQ_RAWBLOCK_URL`: the Bitcoin Signet node's IP address.
- `ZMQ_RAWTX_URL`: the Bitcoin Signet node's IP address.
- `CONSUMER_EOTS_MANAGER_ADDRESS`: the Babylon finality system's IP address.
- `FINALITY_GADGET_RPC`: the Babylon finality system's IP address.
- `NEXT_PUBLIC_FINALITY_GADGET_API_URL`: the Babylon finality system's IP address.

Besides these, you will need to set the following variables:

- `BABYLON_PREFUNDED_KEY_MNEMONIC`: the mnemonic for the wallet you used to claim BBN tokens in the previous step.
- `CONSUMER_ID`: this is the identifier for your OP-Stack chain registration on Babylon, you can set it to anything you want (the convention we use is `<chain_type>-<chain_name>-<chain_id>-<version>`, e.g. `op-stack-tohma-706114-0001`).
- `CONSUMER_CHAIN_NAME`: this is a human-readable name for your chain.
- `OP_FP_MONIKER`: this is a human-readable name for your OP-Stack chain's finality provider.
- `L2_RPC_URL`: this is your OP-Stack chain's RPC URL.

### 3. Set Babylon keys

This step

- imports the pre-funded Babylon key, which will be used to deploy the finality contract, register your finality provider, create BTC delegation in later steps.
- generates a new account for your OP-Stack chain's finality provider.
- funds it with the pre-funded Babylon account, to pay for gas fees when submitting finality votes.

```bash
make set-babylon-keys
```

### 4. Register OP-Stack chain

Register your OP-Stack chain to Babylon.

```bash
make register-consumer-chain
```

### 5. Deploy finality contract

Deploy the finality contract for your OP-Stack chain. Finality votes are submitted to this contract.

```bash
make deploy-cw-contract
```

Once deployed, the contract address is printed to your console and stored at `.deploy/contract/contract-address.txt`.

### 6. Start the Babylon BTC Staker

Start the Babylon BTC Staker, which is used to create the BTC delegation for your OP-Stack chain finality provider.

```bash
make start-babylon-btc-staker
```

### 7. Start the EOTS Manager and Finality Provider

Start the EOTS Manager for your OP-Stack chain finality provider.

```bash
make start-consumer-eotsmanager
```

Start your OP-Stack chain's Finality Provider, and then register it to Babylon.

```bash
make start-consumer-finality-provider
make register-op-consumer-fp
```

### 8. Start the Finality Gadget

Start the Finality Gadget, which provides the query interface for BTC finalized status of your OP-Stack chain's blocks.

```bash
make start-finality-gadget
```

### 9. Enable the Finality Gadget on OP-Stack chain

**Note:** This assumes your OP-Stack chain was deployed using the [OP chain deployment](https://github.com/Snapchain/op-chain-deployment/blob/main/README.md). This step will only work if you are using Snapchain's fork of `op-node`.

On the machine where your OP-Stack chain is deployed, update `BBN_FINALITY_GADGET_RPC` (similar to `FINALITY_GADGET_RPC` above) in `.env` file.

Then restart the `op-node` service:

```bash
make l2-op-node-restart
```

### 10. Create BTC delegation and wait for activation

Create the BTC delegation for your OP-Stack chain's finality provider.

```bash
make create-btc-delegation
```

Wait for the delegation activation, which takes about 3 BTC blocks. You can check the delegation status by the following command:

```bash
make check-btc-delegation
```

### 11. Set `enabled` to `true` in finality contract

Before setting `IS_ENABLED=true`, first wait for your OP-Stack chain's finalized block to be above the BTC delegation activation height. You can check this by comparing the timestamp of the finalized block with the btc activation timestamp.

```bash
# to find the latest finalized block
curl -sf <l2_rpc_url> -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["finalized",false],"id":1}'

# to find the btc activation timestamp
docker logs finality-gadget -f --tail 100
```

Once the BTC delegation is activated, set the `IS_ENABLED=true` in the `.env.babylon-integration` file and then run:

```bash
make toggle-cw-killswitch
```

This should set the `is_enabled` field to `true` in the CW contract. You can verify this by querying the `is_enabled` field:

```bash
babylond query wasm contract-state smart $CONTRACT_ADDR '{"is_enabled":{}}' --chain-id euphrates-0.5.0 --node https://rpc-euphrates.devnet.babylonlabs.io -o json
```

### 12. Start the finality explorer

```bash
make start-finality-explorer
```

You should now be able to access the frontend at `http://<your-server-ip>:13000` and monitor the finality status of your OP-Stack chain.

### 13. Verify the integration

You can verify the integration by creating a transaction on the L2 chain and verify its finalization status in the finality explorer. It should take just a few seconds to be BTC-finalized, thus enabling fast finality in various use cases.

If you plan to build any applications using the fast finality feature, feel free to reach out to us at [info@snapchain.dev](mailto:info@snapchain.dev).

## Troubleshooting

### 1. BTC wallet balance null or no unspent outputs

After running `verify-bitcoin-sync-balance.sh`, the BTC wallet should be loaded to bitcoind. If not, you will run into null balance or no unspent outputs errors when running `create-btc-delegations.sh`.

To check the wallet balance:

```
docker exec bitcoind /bin/sh -c "bitcoin-cli -signet -rpcuser=<BITCOIN_RPC_USER> -rpcpassword=<BITCOIN_RPC_PASS> -rpcwallet=<BTC_WALLET_NAME> listunspent"
```

To check unspent outputs:

```
docker exec bitcoind /bin/sh -c "bitcoin-cli -signet -rpcuser=<BITCOIN_RPC_USER> -rpcpassword=<BITCOIN_RPC_PASS> -rpcwallet=<BTC_WALLET_NAME> getbalance"
```

If your wallet balance is 0 or you have no unspent outputs, you may need to re-load the wallet:

```
docker exec bitcoind /bin/sh -c "bitcoin-cli -signet -rpcuser=<BITCOIN_RPC_USER> -rpcpassword=<BITCOIN_RPC_PASS> -rpcwallet=<BTC_WALLET_NAME> unloadwallet <BTC_WALLET_NAME>"

docker exec bitcoind /bin/sh -c "bitcoin-cli -signet -rpcuser=<BITCOIN_RPC_USER> -rpcpassword=<BITCOIN_RPC_PASS> -rpcwallet=<BTC_WALLET_NAME> loadwallet <BTC_WALLET_NAME>"
```

Now recheck the balance and unspent outputs.
