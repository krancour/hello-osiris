################################################################################
# Version details                                                              #
################################################################################

GIT_VERSION = $(shell git describe --always --abbrev=7 --dirty)

ifdef REL_VERSION
	HELLO_OSIRIS_VERSION := $(REL_VERSION)
else
	HELLO_OSIRIS_VERSION := devel
endif

################################################################################
# Go build details                                                             #
################################################################################

BASE_PACKAGE_NAME := github.com/krancour/hello-osiris

LDFLAGS = -w -X $(BASE_PACKAGE_NAME)/pkg/version.commit=$(GIT_VERSION) \
	-X $(BASE_PACKAGE_NAME)/pkg/version.version=$(HELLO_OSIRIS_VERSION)

################################################################################
# Containerized development environment-- or lack thereof                      #
################################################################################

ifneq ($(SKIP_DOCKER),true)
	DEV_IMAGE := quay.io/deis/lightweight-docker-go:v0.5.0
	DOCKER_CMD := docker run \
		-it \
		--rm \
		-e SKIP_DOCKER=true \
		-v $$(pwd):/go/src/$(BASE_PACKAGE_NAME) \
		-w /go/src/$(BASE_PACKAGE_NAME) $(DEV_IMAGE)
endif

################################################################################
# Docker images we build and publish                                           #
################################################################################

ifdef DOCKER_REGISTRY
	DOCKER_REGISTRY := $(DOCKER_REGISTRY)/
endif

ifdef DOCKER_REGISTRY_NAMESPACE
	DOCKER_REGISTRY_NAMESPACE := $(DOCKER_REGISTRY_NAMESPACE)/
endif

BASE_IMAGE_NAME        := hello-osiris

RC_IMAGE_NAME          := $(DOCKER_REGISTRY)$(DOCKER_REGISTRY_NAMESPACE)$(BASE_IMAGE_NAME):$(GIT_VERSION)
RC_MUTABLE_IMAGE_NAME  := $(DOCKER_REGISTRY)$(DOCKER_REGISTRY_NAMESPACE)$(BASE_IMAGE_NAME):edge

REL_IMAGE_NAME         := $(DOCKER_REGISTRY)$(DOCKER_REGISTRY_NAMESPACE)$(BASE_IMAGE_NAME):$(REL_VERSION)
REL_MUTABLE_IMAGE_NAME := $(DOCKER_REGISTRY)$(DOCKER_REGISTRY_NAMESPACE)$(BASE_IMAGE_NAME):latest

################################################################################
# Utility targets                                                              #
################################################################################

.PHONY: clean
clean:
	rm -rf bin

# Allow developers to step into the containerized development environment--
# unconditionally requires docker
.PHONY: dev
dev:
	$(DOCKER_CMD) bash

# Install/update dependencies
.PHONY: dep
dep:
	$(DOCKER_CMD) dep ensure -v

################################################################################
# Tests                                                                        #
################################################################################

# Verifies there are no disrepancies between desired dependencies and the
# tracked, vendored dependencies
.PHONY: verify-vendored-code
verify-vendored-code:
	$(DOCKER_CMD) scripts/verify-vendored-code.sh

# Executes unit tests
.PHONY: test-unit
test-unit:
	$(DOCKER_CMD) scripts/test-unit.sh

# Executes an extensive series of lint checks against code
.PHONY: lint
lint:
	$(DOCKER_CMD) scripts/lint.sh

################################################################################
# Build / publish Docker images                                                #
################################################################################

# Build the hello-osiris binaries and Docker image
.PHONY: build
build:
	docker build \
		--build-arg BASE_PACKAGE_NAME='$(BASE_PACKAGE_NAME)' \
		--build-arg LDFLAGS='$(LDFLAGS)' \
		-t $(RC_IMAGE_NAME) \
		.
	docker tag $(RC_IMAGE_NAME) $(RC_MUTABLE_IMAGE_NAME)

# Push release candidate image
.PHONY: push-rc
push-rc: build
	docker push $(RC_IMAGE_NAME)
	docker push $(RC_MUTABLE_IMAGE_NAME)

# Rebuild and push officially released, semantically versioned images with
# semantically versioned binary
.PHONY: push-release
push-release:
ifndef REL_VERSION
	$(error REL_VERSION is undefined)
endif
	@# This pull is a verification that this commit has successfully cleared the
	@# master pipeline.
	docker pull $(RC_IMAGE_NAME)
	docker build \
		--build-arg BASE_PACKAGE_NAME='$(BASE_PACKAGE_NAME)' \
		--build-arg LDFLAGS='$(LDFLAGS)' \
		-t $(REL_IMAGE_NAME) \
		.
	docker tag $(REL_IMAGE_NAME) $(REL_MUTABLE_IMAGE_NAME)
	docker push $(REL_IMAGE_NAME)
	docker push $(REL_MUTABLE_IMAGE_NAME)

################################################################################
# Build / publish the gRPC client                                              #
################################################################################

# Build the hello-osiris binaries and Docker image
.PHONY: build-client
build-client:
	$(DOCKER_CMD) scripts/build-client.sh

.PHONY: publish-client
publish-client: build-client
ifndef GIT_FULL_SHA
	$(error GIT_FULL_SHA is undefined)
endif
ifndef REL_VERSION
	$(error REL_VERSION is undefined)
endif
ifndef GITHUB_TOKEN
	$(error GITHUB_TOKEN is undefined)
endif
ifndef GITHUB_PROJECT_USERNAME
	$(error GITHUB_PROJECT_USERNAME is undefined)
endif
ifndef GITHUB_PROJECT_REPONAME
	$(error GITHUB_PROJECT_REPONAME is undefined)
endif
	$(DOCKER_CMD) scripts/publish-client.sh
