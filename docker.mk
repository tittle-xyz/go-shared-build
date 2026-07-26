# docker.mk — container targets for tittle-xyz Go services.
#
# Opt in from a service's Makefile, after go.mk:
#
#   include $(SHARED_BUILD_DIR)/go.mk
#   include $(SHARED_BUILD_DIR)/docker.mk
#
# CLIs skip it. Kept separate so `make` in a CLI project doesn't advertise
# container targets it has no Dockerfile for.

REGISTRY   ?= ghcr.io
IMAGE_OWNER ?= tittle-xyz
IMAGE      ?= $(REGISTRY)/$(IMAGE_OWNER)/$(APP)
IMAGE_TAG  ?= $(VERSION)
DOCKERFILE ?= Dockerfile
# Match the release workflow's default; override for a local arm64 build.
DOCKER_PLATFORM ?= linux/amd64
DOCKER_RUN_PORT ?= 8080

.PHONY: docker-build
docker-build: ## Build the container image locally
	docker build \
	  --platform $(DOCKER_PLATFORM) \
	  --build-arg VERSION=$(IMAGE_TAG) \
	  -f $(DOCKERFILE) \
	  -t $(IMAGE):$(IMAGE_TAG) \
	  .
	@echo "built $(IMAGE):$(IMAGE_TAG)"

.PHONY: docker-run
docker-run: docker-build ## Build and run the image, publishing its port
	docker run --rm -it \
	  -p $(DOCKER_RUN_PORT):$(DOCKER_RUN_PORT) \
	  -e ADDR=":$(DOCKER_RUN_PORT)" \
	  $(IMAGE):$(IMAGE_TAG)

.PHONY: docker-push
docker-push: ## Push the image (CI does this on release; manual pushes are a fallback)
	docker push $(IMAGE):$(IMAGE_TAG)

.PHONY: image
image: ## Print the fully qualified image reference
	@echo $(IMAGE):$(IMAGE_TAG)
