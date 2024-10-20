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
