# vim:ft=make:
APP_NAME := ghcr.io/mpepping/podshell
CONTAINER_NAME := podshell

.PHONY: help
help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

build: ## Build the image
	docker build -t $(APP_NAME):latest .

push: ## Push the image
	docker push $(APP_NAME):latest

clean: ## Remove the image
	docker rmi $(APP_NAME):latest

run start: ## Start the container
	docker run -it --rm --name $(CONTAINER_NAME) $(APP_NAME):latest

stop: ## Stop the container
	docker rm -f $(CONTAINER_NAME)

test: ## Test the container build
	docker run -it --rm $(APP_NAME):latest \
		"env | sort && binenv version && dbin info"
