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
	@./scripts/babylon-integration/init-btc-staker-dir.sh
	@docker compose -f docker/docker-compose-babylon-integration.yml up -d btc-staker
.PHONY: start-babylon-btc-staker

stop-babylon-btc-staker:
	@docker compose -f docker/docker-compose-babylon-integration.yml down btc-staker
	@rm -rf ${PWD}/.btc-staker
.PHONY: stop-babylon-btc-staker

start-consumer-eotsmanager:
	@./scripts/babylon-integration/init-consumer-eots-dir.sh
.PHONY: start-consumer-eotsmanager

stop-consumer-eotsmanager:
	@rm -rf ${PWD}/.consumer-eotsmanager
.PHONY: stop-consumer-eotsmanager