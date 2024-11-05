# BTC Staking Integration for OP-Stack Chains

This guide describes how to integreate the Babylon Bitcoin Staking protocol to an OP-Stack chain.

The OP-Stack chain is recommended to be deployed using https://github.com/Snapchain/op-chain-deployment.

It's recommended you skim through this guide before starting the following steps.

## System Recommendations

The guide was tested on:
- a Debian 12 x64 machine on Digital Ocean
- 8GB Memory
- 160GB Disk

It's recommended you execute the following steps on a similar machine.

## Dependencies

The following dependencies are required on your machine.

| Dependency      | Version | Version Check Command |
| ----------- | ----------- | ----------- |
| [git](https://git-scm.com/)      | ^2       | `git --version`       |
| [docker](https://www.docker.com/)      | ^20       | `docker --version`       |
| [docker compose](https://docs.docker.com/compose/)      | ^2.20       | `docker compose version`       |
| [make](https://linux.die.net/man/1/make)      | ^3       | `make --version`       |
| [curl](https://curl.se/)      | ^8       | `curl --version`       |
| [jq](https://github.com/jqlang/jq)      | ^1.6       | `jq --version`       |


## Setup Bitcoin node

A Bitcoin node is required to run the Babylon BTC Staker. You will need to import a private key with some BTC into the Bitcoin node. If you don't have one, you can generate a new account using OKX wallet and export the private key. To get some test BTC, you can use faucets such as https://signetfaucet.com/. To integrate with Babylon Euphrates 0.5.0 devnet, you need to use the signet network.

1. Copy the `.env.bitcoin.example` file to `.env.bitcoin` and set the variables

    ```bash
    cp .env.bitcoin.example .env.bitcoin
    ```

    * The `NETWORK` variable can be either `regtest` or `signet`.
    * The `BTC_PRIVKEY` variable must be a valid Bitcoin private key in WIF format.

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

## Integrate Babylon finality system with OP-Stack chain

This section describes how to integrate Babylon finality system to Babylon Euphrates 0.5.0 devnet with OP-Stack chain.

Before starting the following steps, please make sure:

* your Bitcoin Signet node is synced and has a wallet that has signet BTC balance.
* your OP-Stack chain is running and have at least one finalized block. For more details about how to setup an OP-Stack chain with BTC staking support, please refer to the [OP chain deployment](https://github.com/Snapchain/op-chain-deployment/blob/main/README.md) repo.


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

Replace the IP with your server's IP in the following variables:
- `BITCOIN_RPC_HOST`: for the Bitcoin Signet node.
- `ZMQ_RAWBLOCK_URL`: for the Bitcoin Signet node.
- `ZMQ_RAWTX_URL`: for the Bitcoin Signet node.
- `CONSUMER_EOTS_MANAGER_ADDRESS`
- `FINALITY_GADGET_RPC`

Configure the following variables:
- `BABYLON_PREFUNDED_KEY_MNEMONIC`: the mnemonic for the address you used to claim BBN tokens in the previous step.
- `CONSUMER_ID`: this is the identifier for your OP-Stack chain registration on Babylon, you can set it to anything.
- `CONSUMER_CHAIN_NAME`: this is a human-readable name for your chain.
- `OP_FP_MONIKER`: this is a human-readable name for your OP-Stack chain's finality provider.
- `L2_RPC_URL`: this is your OP-Stack chain's RPC URL.

### 3. Set Babylon keys

This step imports the pre-funded Babylon key, which will be used to deploy cw contract, btc-staker, register OP-Stack chain, etc.

It also generates a new Babylon account for your OP-Stack chain's finality provider and funds it with the pre-funded Babylon account, because the finality provider needs to have some BBN tokens to pay for the gas fees for submitting finality votes.

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

### 6. Start the Babylon BTC Staker

Start the Babylon BTC Staker, used to create the BTC delegation for your OP-Stack chain finality provider.

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

**Note:** This assumes your OP-Stack chain was deployed using the [OP chain deployment](https://github.com/Snapchain/op-chain-deployment/blob/main/README.md).

On the machine where your OP-Stack chain is deployed, update the `BBN_FINALITY_GADGET_RPC` (similar to `FINALITY_GADGET_RPC` above) in `.env` file.

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

Once the BTC delegation is activated, set the `IS_ENABLED=true` in the `.env.babylon-integration` file and then run:

```bash
make toggle-cw-killswitch
```

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
