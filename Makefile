.PHONY: all clean build test lint run buildMultiArchRelease docker-buildx-push help
.DEFAULT_GOAL := help

VERSION := $(shell git describe --always --tags)
BUILD_TIME=$(shell date '+%Y%m%d-%H%M%S')
DOCKER_IMAGE_NAME="spx01/blocky"
BINARY_NAME=blocky
BIN_OUT_DIR=bin

all: test lint build ## Build binary (with tests)

clean: ## cleans output directory
	$(shell rm -rf $(BIN_OUT_DIR)/*)

build:  ## Build binary
	go build -v -ldflags="-w -s -X main.version=${VERSION} -X main.buildTime=${BUILD_TIME}" -o $(BIN_OUT_DIR)/$(BINARY_NAME)$(BINARY_SUFFIX)

test:  ## run tests
	go test -v -coverprofile=coverage.txt -covermode=atomic -cover ./...

lint: ## run golangcli-lint checks
	$(shell go env GOPATH)/bin/golangci-lint run

run: build ## Build and run binary
	./$(BIN_OUT_DIR)/$(BINARY_NAME)

buildMultiArchRelease: ## builds binary for multiple archs
	$(MAKE) build GOARCH=arm GOARM=6 BINARY_SUFFIX=_${VERSION}_arm32v6
	$(MAKE) build GOARCH=amd64 BINARY_SUFFIX=_${VERSION}_amd64

docker-buildx-push:  ## Build multi arch docker images and push
	docker buildx build \
            --platform linux/386,linux/amd64,linux/arm/v6,linux/arm/v7,linux/arm64 \
            --tag ${DOCKER_IMAGE_NAME}:${VERSION} --push .
	docker buildx build \
            --platform linux/386,linux/amd64,linux/arm/v6,linux/arm/v7,linux/arm64 \
            --tag ${DOCKER_IMAGE_NAME}:latest --push . 

help:  ## Shows help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
