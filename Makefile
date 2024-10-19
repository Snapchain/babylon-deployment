start-babylon:
	@./scripts/babylon-devnet/init-testnets-dir.sh
	@$(DOCKER) compose -f docker/docker-compose-babylon.yml up -d