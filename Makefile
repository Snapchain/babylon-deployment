start-babylon:
	@./scripts/babylon-devnet/init-testnets-dir.sh
	@docker compose -f docker/docker-compose-babylon.yml up -d

start-bitcoin:
	@docker compose -f docker/docker-compose-bitcoin.yml up -d

stop-bitcoin:
	@./scripts/bitcoin/stop.sh

