# tools.mk — pinned developer tooling.
#
# Tool versions live here, not in each project's go.mod, so projects don't carry
# tool dependencies and a version bump is a shared-build release rather than N
# pull requests.
#
# Tools install to a cache shared by every project on the machine, for two
# reasons. Building golangci-lint from source takes minutes, and a per-project
# cache would charge that to every new repo — the exact friction this repo exists
# to remove. And the cache must live outside .build/, which `make update-build`
# wipes, or every shared-build bump would pay for a rebuild too.
#
# Binaries carry their version in the filename, so bumping a pin installs
# alongside the old one; switching branches or projects never rebuilds.
# Set TOOLS_DIR to something repo-local if a project needs to be hermetic.

TOOLS_DIR ?= $(if $(XDG_CACHE_HOME),$(XDG_CACHE_HOME),$(HOME)/.cache)/tittle-xyz/go-tools
TOOLS_BIN ?= $(abspath $(TOOLS_DIR)/bin)

GOLANGCI_LINT_VERSION ?= v2.12.2
GORELEASER_VERSION    ?= v2.12.7

GOLANGCI_LINT := $(TOOLS_BIN)/golangci-lint-$(GOLANGCI_LINT_VERSION)
GORELEASER    := $(TOOLS_BIN)/goreleaser-$(GORELEASER_VERSION)

# A project that wants to diverge drops its own .golangci.yml at the repo root;
# otherwise it gets the shared config. Divergence should be rare and deliberate.
GOLANGCI_CONFIG ?= $(if $(wildcard .golangci.yml),.golangci.yml,$(abspath $(SB)/golangci.yml))

$(TOOLS_BIN):
	@mkdir -p $(TOOLS_BIN)

# `go install` writes an unversioned name; rename it so several pinned versions
# can coexist and switching pins never rebuilds one already on disk.
$(GOLANGCI_LINT): | $(TOOLS_BIN)
	@echo "installing golangci-lint $(GOLANGCI_LINT_VERSION) (one-off, a minute or two)"
	@GOBIN=$(TOOLS_BIN) $(GO) install \
	  github.com/golangci/golangci-lint/v2/cmd/golangci-lint@$(GOLANGCI_LINT_VERSION)
	@mv $(TOOLS_BIN)/golangci-lint $@

$(GORELEASER): | $(TOOLS_BIN)
	@echo "installing goreleaser $(GORELEASER_VERSION) (one-off, a minute or two)"
	@GOBIN=$(TOOLS_BIN) $(GO) install \
	  github.com/goreleaser/goreleaser/v2@$(GORELEASER_VERSION)
	@mv $(TOOLS_BIN)/goreleaser $@

.PHONY: tools-clean
tools-clean: ## Remove installed tools, including versions no longer pinned
	rm -rf $(TOOLS_DIR)

.PHONY: tools
tools: $(GOLANGCI_LINT) ## Install pinned developer tooling
	@echo "tools installed in $(TOOLS_BIN)"

.PHONY: tools-versions
tools-versions: ## Print pinned tool versions
	@echo "golangci-lint $(GOLANGCI_LINT_VERSION)"
	@echo "goreleaser    $(GORELEASER_VERSION)"

# Build a release locally without tagging or publishing — useful for checking
# that .goreleaser.yaml is valid before it runs for real on a release.
.PHONY: snapshot
snapshot: $(GORELEASER) ## Build a local release snapshot (no publish)
	$(GORELEASER) release --snapshot --clean
