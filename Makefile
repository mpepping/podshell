# vim:ft=make:
APP_NAME=ghcr.io/mpepping/podshell
OS_NAME := $(shell uname -s | tr A-Z a-z)
PLATFORMS ?= linux/amd64,linux/arm64

# Auto-detect container runtime
CONTAINER_RUNTIME := $(shell which container 2>/dev/null || which docker 2>/dev/null || which podman 2>/dev/null || echo "")

ifeq ($(CONTAINER_RUNTIME),)
$(error No docker, podman or container found in PATH)
endif


help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

.PHONY: help build build-amd64 build-arm64 build-all lint push pull clean start stop test smoke runtime

build: ## Build the image for the local platform
	$(CONTAINER_RUNTIME) build -t $(APP_NAME):latest .

build-amd64: ## Build the image for linux/amd64
	$(CONTAINER_RUNTIME) build --platform linux/amd64 -t $(APP_NAME):latest .

build-arm64: ## Build the image for linux/arm64
	$(CONTAINER_RUNTIME) build --platform linux/arm64 -t $(APP_NAME):latest .

build-all: ## Build multi-platform (see PLATFORMS), without pushing (mirrors CI)
	docker buildx build --platform $(PLATFORMS) --output "type=image,push=false" --file ./Dockerfile .

lint: ## Lint the Dockerfile (hadolint) and shell scripts (shellcheck)
	$(CONTAINER_RUNTIME) run --rm -i -v $(PWD)/.hadolint.yaml:/.config/hadolint.yaml \
		ghcr.io/hadolint/hadolint hadolint --config /.config/hadolint.yaml - < Dockerfile
	$(CONTAINER_RUNTIME) run --rm -v $(PWD):/mnt -w /mnt koalaman/shellcheck:stable \
		test/smoke.sh include/etc/profile.d/*.sh include/etc/bash/*.sh \
		include/usr/local/bin/_add_binenv include/usr/local/bin/_add_dbin \
		include/usr/local/bin/podshell-motd

push: ## Push the image
ifneq ($(findstring container,$(CONTAINER_RUNTIME)),)
	$(CONTAINER_RUNTIME) image push $(APP_NAME):latest
else
	$(CONTAINER_RUNTIME) push $(APP_NAME):latest
endif

pull: ## Pull the image
ifneq ($(findstring container,$(CONTAINER_RUNTIME)),)
	$(CONTAINER_RUNTIME) image pull $(APP_NAME):latest
else
	$(CONTAINER_RUNTIME) pull $(APP_NAME):latest
endif

clean: ## Remove the image
ifneq ($(findstring container,$(CONTAINER_RUNTIME)),)
	$(CONTAINER_RUNTIME) image rm $(APP_NAME):latest
else
	$(CONTAINER_RUNTIME) rmi $(APP_NAME):latest
endif

start: ## Start the container
	$(CONTAINER_RUNTIME) run -it --rm --name podshell $(APP_NAME):latest

stop: ## Stop the container
	$(CONTAINER_RUNTIME) rm -f podshell

test: ## Test the container build
	$(CONTAINER_RUNTIME) run -it --rm $(APP_NAME):latest \
		"env | sort && binenv version && dbin info"

smoke: ## Run the smoke test suite against the built image
	CONTAINER_RUNTIME=$(CONTAINER_RUNTIME) ./test/smoke.sh $(APP_NAME):latest

runtime: ## Show detected container runtime and OS
	@echo "Using container runtime: $(CONTAINER_RUNTIME) on $(OS_NAME)"

