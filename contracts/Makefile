SHELL := /bin/bash

.PHONY: build test ci export-abi deploy

build:
	scarb build

test:
	scarb test

ci: build test

export-abi:
	./export_abi.sh

deploy:
	./deploy.sh $(ACCOUNT_ADDRESS) $(PRIVATE_KEY)
