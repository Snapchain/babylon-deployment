# babylon-deployment

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

## Setup Babylon BTC Staker

**Note**: This step requires installing `babylond` and importing the key.

0. Check if the key is imported

    ```bash
    babylond keys list --keyring-backend test
    ```

1. Copy the `.env.babylon-integration.example` file to `.env.babylon-integration` and set the variables

    ```bash
    cp .env.babylon-integration.example .env.babylon-integration
    ```

2. Start the Babylon BTC Staker

    ```bash
    make start-babylon-btc-staker
    ```

## Troubleshooting

1. BTC wallet balance null or no unspent outputs

After running `verify-bitcoin-sync-balance.sh`, the BTC wallet should be loaded to bitcoind. If not, you will run into null balance or no unspent outputs errors when running `create-btc-delegations.sh`.

To check the wallet balance:

```
docker exec bitcoind /bin/sh -c "bitcoin-cli -signet -rpcuser=rpcuser -rpcpassword=rpcpass -rpcwallet=btcwallet listunspent"
```

To check unspent outputs:

```
docker exec bitcoind /bin/sh -c "bitcoin-cli -signet -rpcuser=rpcuser -rpcpassword=rpcpass -rpcwallet=btcwallet getbalance"
```

If your wallet balance is 0 or you have no unspent outputs, you may need to re-load the wallet:

```
docker exec bitcoind /bin/sh -c "bitcoin-cli -signet -rpcuser=rpcuser -rpcpassword=rpcpass -rpcwallet=btcwallet unloadwallet btcwallet"

docker exec bitcoind /bin/sh -c "bitcoin-cli -signet -rpcuser=rpcuser -rpcpassword=rpcpass -rpcwallet=btcwallet loadwallet btcwallet"
```

Now recheck the balance and unspent outputs.
