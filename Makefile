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

start-finality-explorer:
	@./scripts/babylon-integration/start-finality-explorer.sh
.PHONY: start-finality-explorer

stop-finality-explorer:
	@./scripts/babylon-integration/stop-finality-explorer.sh
.PHONY: stop-finality-explorer

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

deploy-cw-contract:
	@./scripts/babylon-integration/deploy-contract-and-store-address.sh
.PHONY: deploy-cw-contract

set-babylon-keys:
	@./scripts/babylon-integration/set-babylon-keys.sh
.PHONY: set-babylon-keys

register-consumer-chain:
	@./scripts/babylon-integration/register-consumer-chain.sh
.PHONY: register-consumer-chain

set-cw-enabled-value:
	@./scripts/babylon-integration/set-cw-enabled-value.sh
.PHONY: set-cw-enabled-value