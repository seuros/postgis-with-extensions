# Define the image name and tag
IMAGE_NAME=debian-postgis
IMAGE_TAG=latest

# Default target: Build the Docker image
build:
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .

# Target to build with a custom name
build-with-name:
	docker build -t $(name):$(IMAGE_TAG) .

# Target to clean up dangling images
clean:
	docker system prune -f

# Target to list all images
list:
	docker images

test:
	docker compose up

# Help target to display available commands
help:
	@echo "Usage: make <target>"
	@echo
	@echo "Targets:"
	@echo "  build              Build the Docker image with default name $(IMAGE_NAME)"
	@echo "  build-with-name    Build the Docker image with a custom name: make build-with-name name=<image-name>"
	@echo "  clean              Clean up dangling Docker images"
	@echo "  list               List all Docker images"
	@echo "  test               Test if the server can install and query database"
	@echo "  help               Show this help message"