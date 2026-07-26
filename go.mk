# go.mk — shared build targets for tittle-xyz Go projects.
#
# Consumed by pinning a tag in the project Makefile; see README.md. Everything a
# Go project here needs to build, test, lint and update itself lives in this file
# and its siblings, so a fix lands once and every project picks it up with
# `make update-build`.
#
# Written for GNU Make 3.81 (what macOS ships) — no .ONESHELL, no $(file ...).

# Directory this file lives in, captured before any nested include rewrites
# MAKEFILE_LIST. Everything below refers to siblings through $(SB).
SB := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))

# ---- project knobs -----------------------------------------------------------
# Override any of these above the include line in the project Makefile.

# Binary/app name. Defaults to the directory name, which is right often enough.
APP        ?= $(notdir $(CURDIR))
# Package to build. Single-binary layout by default.
MAIN       ?= ./cmd/$(APP)
BIN_DIR    ?= bin
BINARY     := $(BIN_DIR)/$(APP)

# Version stamped into the binary. Releases override this with the tag; a local
# build reports something like v0.2.0-3-gcb91f2a-dirty, or "dev" outside git.
VERSION    ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo dev)
# Variable the version is stamped into. Templates declare `var version = "dev"`.
VERSION_VAR ?= main.version
GO_LDFLAGS ?= -X $(VERSION_VAR)=$(VERSION)

# Target names to leave undefined, so a project can keep its own version of one
# without Make warning about overriding commands. Set it BEFORE the include:
#
#   SHARED_SKIP_TARGETS := run
#   include $(SHARED_BUILD_DIR)/go.mk
#   run: ## project's own run
#           ...
#
# Use sparingly — the value of the shared build is that `make check` means the
# same thing everywhere. Reach for this when a project has an established target
# name that predates the shared build.
SHARED_SKIP_TARGETS ?=
# Expands to a non-empty string when target $(1) should be defined here.
sb_define = $(if $(filter $(1),$(SHARED_SKIP_TARGETS)),,yes)

GO         ?= go
GOFLAGS    ?=
TEST_FLAGS ?=
COVER_FILE ?= coverage.out

include $(SB)/tools.mk
include $(SB)/update.mk

# ---- meta --------------------------------------------------------------------

# `make` with no target lists what is available. Targets are documented by the
# `##` comment on their rule line; anything without one stays hidden.
.DEFAULT_GOAL := help

.PHONY: help
help: ## List available targets
	@echo "$(APP) — targets (shared build $(SHARED_BUILD_REF))"
	@echo
	@grep -hE '^[a-zA-Z0-9_-]+:.*?## ' $(MAKEFILE_LIST) \
	  | sort -u \
	  | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

.PHONY: version
version: ## Print the version that would be stamped into the binary
	@echo $(VERSION)

# ---- build -------------------------------------------------------------------

.PHONY: build
build: ## Build the binary into bin/
	$(GO) build $(GOFLAGS) -ldflags "$(GO_LDFLAGS)" -o $(BINARY) $(MAIN)

.PHONY: install
install: ## Install the binary into GOBIN
	$(GO) install $(GOFLAGS) -ldflags "$(GO_LDFLAGS)" $(MAIN)

ifneq ($(call sb_define,run),)
.PHONY: run
run: ## Build and run the binary (pass args with ARGS="...")
	$(GO) run $(GOFLAGS) -ldflags "$(GO_LDFLAGS)" $(MAIN) $(ARGS)
endif

.PHONY: clean
clean: ## Remove build output and coverage files
	rm -rf $(BIN_DIR) $(COVER_FILE) dist

# ---- test --------------------------------------------------------------------

.PHONY: test
test: ## Run tests
	$(GO) test $(TEST_FLAGS) ./...

.PHONY: test-race
test-race: ## Run tests with the race detector
	$(GO) test -race $(TEST_FLAGS) ./...

ifneq ($(call sb_define,cover),)
.PHONY: cover
cover: ## Run tests with coverage and print a per-function summary
	$(GO) test -coverprofile=$(COVER_FILE) $(TEST_FLAGS) ./...
	$(GO) tool cover -func=$(COVER_FILE) | tail -1
endif

.PHONY: cover-html
cover-html: cover ## Open the coverage report in a browser
	$(GO) tool cover -html=$(COVER_FILE)

# ---- format / vet / lint -----------------------------------------------------

.PHONY: fmt
fmt: ## Format all Go source in place
	$(GO) fmt ./...

.PHONY: fmt-check
fmt-check: ## Fail if any Go source is not gofmt-clean
	@unformatted="$$(gofmt -l .)"; \
	if [ -n "$$unformatted" ]; then \
	  echo "not gofmt-clean:"; echo "$$unformatted"; \
	  echo "run: make fmt"; \
	  exit 1; \
	fi

.PHONY: vet
vet: ## Run go vet
	$(GO) vet ./...

.PHONY: lint
lint: $(GOLANGCI_LINT) ## Run golangci-lint
	$(GOLANGCI_LINT) run --config $(GOLANGCI_CONFIG)

.PHONY: lint-fix
lint-fix: $(GOLANGCI_LINT) ## Run golangci-lint with --fix
	$(GOLANGCI_LINT) run --config $(GOLANGCI_CONFIG) --fix

.PHONY: tidy
tidy: ## Run go mod tidy
	$(GO) mod tidy

.PHONY: tidy-check
tidy-check: ## Fail if go.mod/go.sum are not tidy
	@cp go.mod go.mod.bak; cp go.sum go.sum.bak 2>/dev/null || true; \
	status=0; \
	if ! $(GO) mod tidy; then \
	  echo "go mod tidy failed"; status=1; \
	else \
	  if ! cmp -s go.mod go.mod.bak; then status=1; fi; \
	  if [ -f go.sum.bak ] && ! cmp -s go.sum go.sum.bak; then status=1; fi; \
	  if [ $$status -ne 0 ]; then echo "go.mod/go.sum are not tidy; run: make tidy"; fi; \
	fi; \
	mv go.mod.bak go.mod; mv go.sum.bak go.sum 2>/dev/null || true; \
	exit $$status

# The gate to run before pushing, and what CI runs. Kept as one name so CI never
# has to enumerate steps — adding a check here rolls out everywhere on update.
.PHONY: check
check: fmt-check tidy-check vet lint test ## Run the full pre-push gate

