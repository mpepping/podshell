# vim:ft=make:
APP_NAME=ghcr.io/mpepping/podshell

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
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

start: ## Start the container
	docker run -it --rm --name podshell $(APP_NAME):latest

stop: ## Stop the container
	docker rm -f podshell

test: ## Test the container build
	docker run -it --rm $(APP_NAME):latest "env | sort"
