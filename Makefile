
USERNAME=maguesse
NAME=$(shell basename $(CURDIR))

VERSION=0.1
TAG=tag

IMAGE=$(USERNAME)/$(NAME)

DOCKER_BUILD_CONTEXT=.
DOCKER_FILE_PATH=Dockerfile


SHELL=/bin/bash
SUBDIRS = $(shell find . -mindepth 2 -name Makefile -exec dirname {} \;)
.PHONY: subdirs $(SUBDIRS)

subdirs: $(SUBDIRS)
$(SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)

.PHONY: help
help: ## This help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

.PHONY: dockerfile $(DOCKER_FILE_PATH) pre-build docker-build post-build build

dockerfile: $(DOCKER_FILE_PATH)
$(DOCKER_FILE_PATH):
	@echo test

build: $(SUBDIRS) $(DOCKER_FILE_PATH) pre-build docker-build post-build ## Build the container

pre-build:

post-build:

docker-build:
	@echo in $(MAKEFILE_LIST)
	@echo "In docker-build $(NAME) $(CURDIR)"
	@echo docker build $(DOCKER_BUILD_ARGS) -t $(IMAGE):$(VERSION) $(DOCKER_BUILD_CONTEXT) -f $(DOCKER_FILE_PATH)

.PHONY: help clean purge


clean: ## Clean

prune: ## Purge
	@docker image prune --force
	@docker volume prune --force
	@docker network prune --force

## Utility functions
define docker_file_exists
@echo exist?
endef
