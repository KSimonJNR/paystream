SHELL := /bin/bash

.PHONY: build test ci export-abi deploy

build:
	cd contracts && scarb build

test:
	cd contracts && scarb test

ci: build test

export-abi:
	cd contracts && ./export_abi.sh

deploy:
	cd contracts && ./deploy.sh $(ACCOUNT_ADDRESS) $(PRIVATE_KEY)
