# ----------------------------------------------------------
# Copyright (C) 2019 Mathieu AGUESSE
#
# This software may be modified and distributed under the
# MIT License. See the LICENSE file for details.
# ----------------------------------------------------------
#  Project's variables
REGISTRY_HOST ?=docker.io
USERNAME ?= maguesse
PROJECT_NAME ?= $(shell basename $(CURDIR))

VERSION ?= 0.1
TAG ?= tag

IMAGE = $(REGISTRY_HOST)/$(USERNAME)/$(PROJECT_NAME)

DOCKER_BUILD_CONTEXT = .
DOCKER_FILE_PATH ?= Dockerfile

MAKEFLAGS += -rR
MAKEFLAGS += --no-print-directory

# You should not update the remaining part of this Makefile
SHELL=/bin/bash
DOCKER=$(shell which docker)
DOCKER_COMPOSE=$(shell which docker-compose)
SUBDIRS=$(shell find . -mindepth 2 -name $(DOCKER_FILE_PATH) -exec dirname {} \;)
.PHONY: subdirs $(SUBDIRS)

subdirs: $(SUBDIRS)
$(SUBDIRS):
	@$(MAKE) -C $@ $(MAKECMDGOALS)

.PHONY: help
help: ## This help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort

.DEFAULT_GOAL := help

.PHONY: pre-build docker-build post-build build

# Little hack : try not to run "build" rules if no Dockerfile is present in the current folder.
ifeq (,$(wildcard $(DOCKER_FILE_PATH)))
# No Dockerfile, nothing to build
BUILD_TARGETS =
PUSH_TARGETS = 
else
BUILD_TARGETS = pre-build docker-build post-build
PUSH_TARGETS =pre-push docker-push post-push
endif

build: $(SUBDIRS) $(BUILD_TARGETS) ## Build the container

pre-build:

post-build:

docker-build: $(DOCKER_FILE_PATH)
	@echo Build image $(IMAGE):$(VERSION)
	@$(DOCKER) build --rm --force-rm $(DOCKER_BUILD_ARGS) -t $(IMAGE):$(VERSION) $(DOCKER_BUILD_CONTEXT) -f $(DOCKER_FILE_PATH)
	@echo Tag image $(IMAGE):latest
	@$(DOCKER) tag $(IMAGE):$(VERSION) $(IMAGE):latest


push: $(SUBDIRS) $(PUSH_TARGETS) ## Push the container

pre-push:

docker-push:
	$(call docker-push-image,$(IMAGE),$(VERSION))
	$(call docker-push-image,$(IMAGE),latest)

post-push:

.PHONY: snapshot

snapshot: build push ## Build and push a snapshot

.PHONY: help clean purge

clean: $(SUBDIRS) ## Clean
	$(call docker-remove-image,$(IMAGE),$(VERSION))
	$(call docker-remove-image,$(IMAGE),latest)

prune: ## Purge
	-$(call docker-remove-dangling,image)
	-$(call docker-remove-dangling,volume)
	-$(call docker-remove-dangling,network)

###########################################################
## Utility functions
###########################################################

# Removes an image given its:
# - name
# - tag or version
define docker-remove-image
@$(DOCKER) image inspect ${1}:${2} > /dev/null 2>&1;\
if [ $$? -eq 0 ]; \
then \
	echo Removing docker image ${1}:${2} ;\
	$(DOCKER) image rm ${1}:${2} ;\
fi
endef

# Removes dangling docker's assets:
# - image
# - volume
# - network
define docker-remove-dangling
@echo Removing dangling ${1}s
@$(DOCKER) ${1} prune --force
endef

# Push an image to a remote repository
# Parameters:
# - image name
# - image tag
define docker-push-image
@echo Pushing image ${1}:${2}
@$(DOCKER) push ${1}:${2}
endef
