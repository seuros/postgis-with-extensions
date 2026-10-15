## Image coordinates (override with `make IMAGE_NAME=...` if desired)
IMAGE_NAME ?= ghcr.io/seuros/postgis-with-extensions

## Versions come from the FROM line of the Dockerfile (single source of truth)
PG_VERSION := $(shell sed -nE 's/^FROM postgres:([0-9]+\.[0-9]+)-.*/\1/p' Dockerfile)
PG_MAJOR   := $(firstword $(subst ., ,$(PG_VERSION)))

ALPINE_DOCKERFILE ?= Dockerfile.alpine
PLATFORMS         ?= linux/amd64,linux/arm64
## Extra flags for docker build, e.g. BUILD_ARGS="--no-cache --build-arg WITH_PGROUTING=0"
BUILD_ARGS        ?=

COMPOSE_TEST = docker compose -p pgx-test

.PHONY: build build-alpine build-all test test-alpine test-all run-test \
        push push-alpine clean-test check-versions help print-vars

## Build the Debian image, tagged :PG_VERSION, :PG_MAJOR and :latest
build: check-versions
	docker build $(BUILD_ARGS) \
	  -t $(IMAGE_NAME):$(PG_VERSION) -t $(IMAGE_NAME):$(PG_MAJOR) -t $(IMAGE_NAME):latest .

## Build the Alpine image, tagged :PG_VERSION-alpine, :PG_MAJOR-alpine and :alpine
build-alpine: check-versions
	docker build -f $(ALPINE_DOCKERFILE) $(BUILD_ARGS) \
	  -t $(IMAGE_NAME):$(PG_VERSION)-alpine -t $(IMAGE_NAME):$(PG_MAJOR)-alpine -t $(IMAGE_NAME):alpine .

build-all: build build-alpine

## Run the SQL suite against the locally built image
test: build
	$(MAKE) --no-print-directory run-test IMAGE_TAG=$(PG_VERSION) IMAGE_FLAVOR=

test-alpine: build-alpine
	$(MAKE) --no-print-directory run-test IMAGE_TAG=$(PG_VERSION) IMAGE_FLAVOR=-alpine

test-all: test test-alpine

# Runs the suite against IMAGE_NAME:IMAGE_TAG IMAGE_FLAVOR (no build); used by CI.
run-test:
	@IMAGE_NAME=$(IMAGE_NAME) IMAGE_TAG=$(IMAGE_TAG) IMAGE_FLAVOR=$(IMAGE_FLAVOR) sh -c '\
	  $(COMPOSE_TEST) run --rm sut; status=$$?; \
	  [ $$status -eq 0 ] || $(COMPOSE_TEST) logs postgres; \
	  $(COMPOSE_TEST) down -v --remove-orphans >/dev/null 2>&1; \
	  exit $$status'

## Multi-arch build + push (CI normally does this; plain `docker push` from a
## single-arch host would clobber the published multi-arch tags)
push: check-versions
	docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) --push \
	  -t $(IMAGE_NAME):$(PG_VERSION) -t $(IMAGE_NAME):$(PG_MAJOR) -t $(IMAGE_NAME):latest .

push-alpine: check-versions
	docker buildx build --platform $(PLATFORMS) -f $(ALPINE_DOCKERFILE) $(BUILD_ARGS) --push \
	  -t $(IMAGE_NAME):$(PG_VERSION)-alpine -t $(IMAGE_NAME):$(PG_MAJOR)-alpine -t $(IMAGE_NAME):alpine .

## Stop and remove test containers and volumes
clean-test:
	$(COMPOSE_TEST) --profile test down -v --remove-orphans

## Fail if the Debian and Alpine Dockerfiles disagree on the Postgres version
check-versions:
	@alpine=$$(sed -nE 's/^FROM postgres:([0-9]+\.[0-9]+)-.*/\1/p' $(ALPINE_DOCKERFILE)); \
	if [ -z "$(PG_VERSION)" ] || [ "$(PG_VERSION)" != "$$alpine" ]; then \
	  echo "PG version mismatch: Dockerfile='$(PG_VERSION)' $(ALPINE_DOCKERFILE)='$$alpine'" >&2; exit 1; \
	fi

help:
	@echo "Usage: make <target>"
	@echo
	@echo "Targets:"
	@echo "  build         Build Debian image  -> :$(PG_VERSION), :$(PG_MAJOR), :latest"
	@echo "  build-alpine  Build Alpine image  -> :$(PG_VERSION)-alpine, :$(PG_MAJOR)-alpine, :alpine"
	@echo "  build-all     Build both flavours"
	@echo "  test          Build + run the SQL suite against the Debian image"
	@echo "  test-alpine   Build + run the SQL suite against the Alpine image"
	@echo "  test-all      Both of the above"
	@echo "  push          Multi-arch ($(PLATFORMS)) build + push of the Debian image"
	@echo "  push-alpine   Multi-arch build + push of the Alpine image"
	@echo "  clean-test    Remove test containers and volumes"
	@echo "  print-vars    Show resolved variables"
	@echo
	@echo "Pass extra docker build flags via BUILD_ARGS, e.g. BUILD_ARGS=--no-cache"

print-vars:
	@echo IMAGE_NAME=$(IMAGE_NAME)
	@echo PG_VERSION=$(PG_VERSION)
	@echo PG_MAJOR=$(PG_MAJOR)
