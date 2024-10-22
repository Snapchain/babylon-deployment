start-babylon:
	@./scripts/babylon-devnet/init-testnets-dir.sh
	@docker compose -f docker/docker-compose-babylon.yml up -d
.PHONY: start-babylon

start-bitcoin:
	@./scripts/bitcoin/start.sh
.PHONY: start-bitcoin

stop-bitcoin:
	@./scripts/bitcoin/stop.sh
.PHONY: stop-bitcoin

verify-bitcoin-sync-balance:
	@./scripts/bitcoin/verify-sync-balance.sh
.PHONY: verify-bitcoin-sync-balance

start-babylon-btc-staker:
	@./scripts/babylon-integration/start-btc-staker.sh
.PHONY: start-babylon-btc-staker

stop-babylon-btc-staker:
	@./scripts/babylon-integration/stop-btc-staker.sh
.PHONY: stop-babylon-btc-staker

start-consumer-eotsmanager:
	@./scripts/babylon-integration/start-consumer-eotsmanager.sh
.PHONY: start-consumer-eotsmanager

stop-consumer-eotsmanager:
	@./scripts/babylon-integration/stop-consumer-eotsmanager.sh
.PHONY: stop-consumer-eotsmanager