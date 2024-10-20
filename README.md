# babylon-deployment

## Start Bitcoin node

1. Copy the `.env.bitcoin.example` file to `.env.bitcoin` and set the variables

    ```bash
    cp .env.bitcoin.example .env.bitcoin
    ```

* The `NETWORK` variable only can be either `regtest` or `signet`.
* The `BTCSTAKER_PRIVKEY` variable must be a valid Bitcoin private key in WIF format.

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
