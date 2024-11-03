# babylon-deployment

## Dependencies

| Dependency      | Version | Version Check Command |
| ----------- | ----------- | ----------- |
| [git](https://git-scm.com/)      | ^2       | `git --version`       |
| [docker](https://www.docker.com/)      | ^20       | `docker --version`       |
| [docker compose](https://docs.docker.com/compose/)      | ^2.20       | `docker compose version`       |
| [make](https://linux.die.net/man/1/make)      | ^3       | `make --version`       |
| [curl](https://curl.se/)      | ^8       | `curl --version`       |
| [jq](https://github.com/jqlang/jq)      | ^1.6       | `jq --version`       |


## Setup Bitcoin node

1. Copy the `.env.bitcoin.example` file to `.env.bitcoin` and set the variables

    ```bash
    cp .env.bitcoin.example .env.bitcoin
    ```

* The `NETWORK` variable only can be either `regtest` or `signet`.
* The `BTC_PRIVKEY` variable must be a valid Bitcoin private key in WIF format.

2. Start the Bitcoin node

    ```bash
    make start-bitcoin
    ```

3. Verify the Bitcoin node is synced and has a balance

    ```bash
    make verify-bitcoin-sync-balance
    ```

4. Stop the Bitcoin node

    ```bash
    make stop-bitcoin
    ```

5. Check the Bitcoin node logs

    ```bash
    docker compose -f docker/docker-compose-bitcoin.yml logs -f bitcoind
    ```

## Integrate Babylon finality system with OP Stack chain

This section describes how to integrate Babylon finality system to Babylon Euphrates 0.5.0 devnet with OP Stack chain.

Before starting the following steps, please make sure:

* your Bitcoin node is synced and has a wallet that has BTC balance on your specified network.
* your OP Stack chain is running and have at least one finalized block. For more details about how to setup OP Stack chain, please refer to the [OP chain deployment](https://github.com/Snapchain/op-chain-deployment/blob/main/README.md).


Firstly, please get some test tokens from the Euphrates faucet

```bash
curl https://faucet-euphrates.devnet.babylonlabs.io/claim \
-H "Content-Type: multipart/form-data" \
-d '{ "address": "<YOUR_BABYLON_ADDRESS>"}'
```

### 1. Setup environment variables

Copy the `.env.babylon-integration.example` file to `.env.babylon-integration`

```bash
cp .env.babylon-integration.example .env.babylon-integration
```

**Configure for Bitcoin**

Based on the previous step `Setup Bitcoin node`, set the following variables with the values:
- `BITCOIN_RPC_PASS`
- `BTC_WALLET_PASS`
    
and replace the IP with your Bitcoin node IP:
- `BITCOIN_RPC_HOST`
- `ZMQ_RAWBLOCK_URL`
- `ZMQ_RAWTX_URL`

**Configure for Babylon**

set your Babylon key's mnemonic, the address should have some BBN tokens, it will be used in the following steps

- `BABYLON_PREFUNDED_KEY_MNEMONIC`

set the following variables to register your OP Stack chain to Babylon:

- `CONSUMER_ID`
- `CONSUMER_CHAIN_NAME`

set your OP Stack chain's finality provider moniker

- `OP_FP_MONIKER`

replace the IP with the Babylon finality system you deployed server IP:

- `CONSUMER_EOTS_MANAGER_ADDRESS`
- `FINALITY_GADGET_RPC`

**Configure for OP Stack chain**

set your OP Stack chain's RPC URL

- `L2_RPC_URL`

### 2. Set Babylon keys

Set the pre-funded Babylon key, used to deploy cw contract, btc-staker, register OP Stack chain, etc. 

Also, generate a new Babylon account for your OP Stack chain's finality provider and fund it with the previously imported pre-funded Babylon account.

```bash
make set-babylon-keys
```

### 3. Register OP Stack chain

Register your OP Stack chain to Babylon.

```bash
make register-consumer-chain
```

### 4. Deploy finality contract

Deploy the finality contract for your OP Stack chain.

```bash
make deploy-cw-contract
```

### 5. Start the Babylon BTC Staker

Start the Babylon BTC Staker, used to create the BTC delegation for your OP Stack chain finality provider.

```bash
make start-babylon-btc-staker
```

### 6. Start the EOTS Manager

Start the EOTS Manager for your OP Stack chain finality provider.

```bash
make start-consumer-eotsmanager
```

### 7. Start the Finality Provider

Start your OP Stack chain's Finality Provider, and then register it to Babylon.

```bash
make start-consumer-finality-provider
make register-op-consumer-fp
```

### 8. Start the Finality Gadget

Start the Finality Gadget, which provides the query interface for BTC finalized status of your OP Stack chain's blocks.

```bash
make start-finality-gadget
```

### 9. Restart OP Stack chain node

Login to your OP Stack chain server, update the `BBN_FINALITY_GADGET_RPC` with the Finality Gadget's gRPC(e.g `<your-server-ip>:50051`) in `.env` file.

```bash
BBN_FINALITY_GADGET_RPC=<FINALITY_GADGET_RPC>
```

And then restart the `op-node` service, run:

```bash
make l2-op-node-restart
```

### 10. Create BTC delegation and wait for activation

Create the BTC delegation for your OP Stack chain finality provider.

```bash
make create-btc-delegation
```

Wait for the delegation activation, which takes about 3 BTC blocks, and then you can check the delegation status by the following command:

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
