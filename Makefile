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

start-consumer-finality-provider:
	@./scripts/babylon-integration/start-consumer-finality-provider.sh
.PHONY: start-consumer-finality-provider

register-op-consumer-fp:
	@./scripts/babylon-integration/register-op-consumer-fp.sh
.PHONY: register-op-consumer-fp

stop-consumer-finality-provider:
	@./scripts/babylon-integration/stop-consumer-finality-provider.sh
.PHONY: stop-consumer-finality-provider

start-finality-gadget:
	@./scripts/babylon-integration/start-finality-gadget.sh
.PHONY: start-finality-gadget

stop-finality-gadget:
	@./scripts/babylon-integration/stop-finality-gadget.sh
.PHONY: stop-finality-gadget

create-btc-delegation:
	@./scripts/babylon-integration/create-btc-delegation.sh
.PHONY: create-btc-delegation

check-btc-delegation:
	@./scripts/babylon-integration/check-btc-delegation.sh
.PHONY: check-btc-delegation

restart-finality-gadget:
	@docker compose -f docker/docker-compose-babylon-integration.yml stop finality-gadget
	@docker compose -f docker/docker-compose-babylon-integration.yml up -d finality-gadget
.PHONY: restart-finality-gadget

restart-babylon-btc-staker:
	@docker compose -f docker/docker-compose-babylon-integration.yml stop btc-staker
	@docker compose -f docker/docker-compose-babylon-integration.yml up -d btc-staker
.PHONY: restart-babylon-btc-staker

restart-consumer-finality-provider:
	@docker compose -f docker/docker-compose-babylon-integration.yml stop consumer-finality-provider
	@docker compose -f docker/docker-compose-babylon-integration.yml up -d consumer-finality-provider
.PHONY: restart-consumer-finality-provider

restart-consumer-eotsmanager:
	@docker compose -f docker/docker-compose-babylon-integration.yml stop consumer-eotsmanager
	@docker compose -f docker/docker-compose-babylon-integration.yml up -d consumer-eotsmanager
.PHONY: restart-consumer-eotsmanager

build-deploy-cw-contract-image:
	@./scripts/deploy-cw-contract/build-docker-image.sh
.PHONY: build-deploy-cw-contract-image

deploy-cw-contract:
	@docker compose -f docker/docker-compose-babylon-integration.yml up -d deploy-cw-contract
.PHONY: deploy-cw-contract
