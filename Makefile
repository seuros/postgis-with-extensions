## Image coordinates (override with `make IMAGE_NAME=...` if desired)
IMAGE_NAME ?= ghcr.io/seuros/postgis-with-extensions

## Extract versions from Dockerfile
PG_VERSION ?= $(shell sed -n 's/^ARG PG_VERSION=\(.*\)/\1/p' Dockerfile)
PG_MAJOR   ?= $(shell echo $(PG_VERSION) | cut -d. -f1)

.PHONY: build build-tags build-no-cache tag push \
        build-alpine tag-alpine push-alpine build-all \
        clean clean-test rebuild-test list test help print-vars

# Default target: build and tag all variants
build: build-tags

# Build the image pinned to PG_VERSION and tag as :PG_MAJOR and :latest
build-tags:
	docker build --build-arg PG_VERSION=$(PG_VERSION) -t $(IMAGE_NAME):$(PG_VERSION) .
	docker tag $(IMAGE_NAME):$(PG_VERSION) $(IMAGE_NAME):$(PG_MAJOR)
	docker tag $(IMAGE_NAME):$(PG_VERSION) $(IMAGE_NAME):latest

# Build without cache, then re-tag
build-no-cache:
	docker build --no-cache --pull --build-arg PG_VERSION=$(PG_VERSION) -t $(IMAGE_NAME):$(PG_VERSION) .
	docker tag $(IMAGE_NAME):$(PG_VERSION) $(IMAGE_NAME):$(PG_MAJOR)
	docker tag $(IMAGE_NAME):$(PG_VERSION) $(IMAGE_NAME):latest

# Tag an existing local image explicitly (useful if you built via compose)
tag:
	docker tag $(IMAGE_NAME):$(PG_VERSION) $(IMAGE_NAME):$(PG_MAJOR)
	docker tag $(IMAGE_NAME):$(PG_VERSION) $(IMAGE_NAME):latest

# Push all tags
push:
	docker push $(IMAGE_NAME):$(PG_VERSION)
	docker push $(IMAGE_NAME):$(PG_MAJOR)
	docker push $(IMAGE_NAME):latest

# ------------------------ Alpine variant ------------------------
ALPINE_DOCKERFILE ?= Dockerfile.alpine
ALPINE_BUILD_ARGS ?=

build-alpine:
	docker build -f $(ALPINE_DOCKERFILE) \
	  --build-arg PG_VERSION=$(PG_VERSION) \
	  $(ALPINE_BUILD_ARGS) \
	  -t $(IMAGE_NAME):$(PG_VERSION)-alpine .
	docker tag $(IMAGE_NAME):$(PG_VERSION)-alpine $(IMAGE_NAME):$(PG_MAJOR)-alpine
	docker tag $(IMAGE_NAME):$(PG_VERSION)-alpine $(IMAGE_NAME):alpine

tag-alpine:
	docker tag $(IMAGE_NAME):$(PG_VERSION)-alpine $(IMAGE_NAME):$(PG_MAJOR)-alpine
	docker tag $(IMAGE_NAME):$(PG_VERSION)-alpine $(IMAGE_NAME):alpine

push-alpine:
	docker push $(IMAGE_NAME):$(PG_VERSION)-alpine
	docker push $(IMAGE_NAME):$(PG_MAJOR)-alpine
	docker push $(IMAGE_NAME):alpine

# Build both Debian and Alpine flavors
build-all: build-tags build-alpine

# Target to clean up dangling images
clean:
	docker system prune -f

# Target to stop and remove the test containers
clean-test:
	docker compose down -v

# Target to rebuild and restart the test environment
rebuild-test: clean-test build
	docker compose up

# Target to list all images
list:
	docker images

# Target to run the test container
test:
	docker compose up --build

# Help target to display available commands
help:
	@echo "Usage: make <target>"
	@echo
	@echo "Targets:"
	@echo "  build              Build and tag :$(PG_VERSION), :$(PG_MAJOR), and :latest"
	@echo "  build-no-cache     Build without cache and re-tag"
	@echo "  tag                Add :$(PG_MAJOR) and :latest tags to an existing :$(PG_VERSION) image"
	@echo "  push               Push :$(PG_VERSION), :$(PG_MAJOR), and :latest to registry"
	@echo "  build-alpine       Build Alpine variant and tag :-alpine variants"
	@echo "  tag-alpine         Add :-alpine tags to an existing Alpine build"
	@echo "  push-alpine        Push Alpine tags (:$(PG_VERSION)-alpine, :$(PG_MAJOR)-alpine, :alpine)"
	@echo "  clean              Clean up dangling Docker images"
	@echo "  clean-test         Stop and remove test containers and their volumes"
	@echo "  rebuild-test       Clean test containers, rebuild image, and restart test environment"
	@echo "  list               List all Docker images"
	@echo "  test               Test if the server can install and query database"
	@echo "  help               Show this help message"

# Show resolved variables
print-vars:
	@echo IMAGE_NAME=$(IMAGE_NAME)
	@echo PG_VERSION=$(PG_VERSION)
	@echo PG_MAJOR=$(PG_MAJOR)
