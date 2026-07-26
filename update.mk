# update.mk — keeping a project current, and keeping the shared build current.
#
# Two different updates live here and they are deliberately separate:
#
#   make update        bump this project's Go toolchain and dependencies
#   make update-build  bump the pinned shared-build release
#
# The first is the "solve it once upstream" half: the policy for what updating a
# Go project means lives in this file, so improving it improves every project.
# The second is how a project picks that improvement up.

# Defaults mirror the ones in the project Makefile so this file is usable even if
# a project trims its preamble.
SHARED_BUILD_REPO ?= https://github.com/tittle-xyz/go-shared-build.git
SHARED_BUILD_REF  ?= main
SHARED_BUILD_DIR  ?= .build
# owner/name form, used to find and rewrite `uses:` refs in workflows.
SHARED_BUILD_SLUG ?= tittle-xyz/go-shared-build

# Optional private overlay, for org-specific targets that must not be public
# (deploy destinations, internal registries). Unset in public projects, which
# then use the public core alone. See go-shared-build-internal.
INTERNAL_BUILD_REPO ?=
INTERNAL_BUILD_REF  ?=
INTERNAL_BUILD_DIR  ?= .build-internal

# The file `update-build` rewrites the pins in.
PROJECT_MAKEFILE  ?= Makefile
# Workflow files whose `uses:` refs are bumped alongside the Makefile pin, so the
# build half and the CI half can never drift onto different versions.
WORKFLOW_GLOB     ?= .github/workflows/*.yml

# ---- updating this project ---------------------------------------------------

.PHONY: update
update: update-go update-deps ## Update the Go toolchain and all dependencies, then verify
	@echo
	@echo "==> verifying the update"
	@$(MAKE) check
	@echo
	@echo "update complete — review 'git diff go.mod go.sum' before committing"

.PHONY: update-go
update-go: ## Bump the go directive to the latest release
	@before="$$(go mod edit -json | sed -n 's/.*"Go": "\([^"]*\)".*/\1/p' | head -1)"; \
	$(GO) get go@latest; \
	$(GO) get toolchain@latest; \
	after="$$(go mod edit -json | sed -n 's/.*"Go": "\([^"]*\)".*/\1/p' | head -1)"; \
	if [ "$$before" = "$$after" ]; then \
	  echo "go directive already current ($$after)"; \
	else \
	  echo "go directive $$before -> $$after"; \
	fi

.PHONY: update-deps
update-deps: ## Update all dependencies to their latest versions and tidy
	$(GO) get -u ./...
	$(GO) mod tidy

.PHONY: update-patch
update-patch: ## Update dependencies to latest patch releases only, and tidy
	$(GO) get -u=patch ./...
	$(GO) mod tidy

.PHONY: outdated
outdated: ## List dependencies with newer versions available
	@$(GO) list -u -m -f '{{if and .Update (not .Indirect)}}{{.Path}} {{.Version}} -> {{.Update.Version}}{{end}}' all \
	  | grep . || echo "all direct dependencies are current"

# ---- updating the shared build ----------------------------------------------

.PHONY: build-sync
build-sync: ## Re-clone the shared build (and overlay, if any) at the pinned refs
	@rm -rf $(SHARED_BUILD_DIR)
	@git -c advice.detachedHead=false clone --quiet --depth 1 \
	  --branch $(SHARED_BUILD_REF) $(SHARED_BUILD_REPO) $(SHARED_BUILD_DIR)
	@rm -rf $(SHARED_BUILD_DIR)/.git
	@echo "shared build synced at $(SHARED_BUILD_REF)"
ifneq ($(INTERNAL_BUILD_REPO),)
	@rm -rf $(INTERNAL_BUILD_DIR)
	@git -c advice.detachedHead=false clone --quiet --depth 1 \
	  --branch $(INTERNAL_BUILD_REF) $(INTERNAL_BUILD_REPO) $(INTERNAL_BUILD_DIR)
	@rm -rf $(INTERNAL_BUILD_DIR)/.git
	@echo "internal build synced at $(INTERNAL_BUILD_REF)"
endif

.PHONY: build-version
build-version: ## Print the pinned build refs
	@echo "shared   $(SHARED_BUILD_REF)"
ifneq ($(INTERNAL_BUILD_REPO),)
	@echo "internal $(INTERNAL_BUILD_REF)"
endif

# Bumps every reference to a build repo in lockstep: the Makefile pin, the
# `uses:` refs in workflows, and the private overlay if the project has one.
# Keeping them on one command is the point — a project can never end up running
# v0.3.0 of the Make targets against v0.1.0 of the CI workflow.
.PHONY: update-build
update-build: ## Bump the shared build (and overlay) to their latest releases
	@$(MAKE) --no-print-directory _bump-one \
	  BUMP_NAME=shared BUMP_VAR=SHARED_BUILD_REF BUMP_REPO="$(SHARED_BUILD_REPO)" \
	  BUMP_CUR=$(SHARED_BUILD_REF) BUMP_SLUG="$(SHARED_BUILD_SLUG)"
ifneq ($(INTERNAL_BUILD_REPO),)
	@$(MAKE) --no-print-directory _bump-one \
	  BUMP_NAME=internal BUMP_VAR=INTERNAL_BUILD_REF BUMP_REPO="$(INTERNAL_BUILD_REPO)" \
	  BUMP_CUR=$(INTERNAL_BUILD_REF) BUMP_SLUG=""
endif
	@$(MAKE) --no-print-directory build-sync
	@echo "review 'git diff' and commit to record the bump"

# Internal helper: resolve the newest v* tag of one build repo and rewrite every
# reference to it. Not meant to be called directly.
.PHONY: _bump-one
_bump-one:
	@latest="$$(git ls-remote --tags --refs --sort=-v:refname $(BUMP_REPO) 'v*' 2>/dev/null \
	  | head -1 | sed 's#.*/##')"; \
	if [ -z "$$latest" ]; then \
	  echo "no release tags found at $(BUMP_REPO)"; exit 1; \
	fi; \
	if [ "$$latest" = "$(BUMP_CUR)" ]; then \
	  echo "$(BUMP_NAME) build already at $$latest"; exit 0; \
	fi; \
	if [ ! -f $(PROJECT_MAKEFILE) ]; then \
	  echo "$(PROJECT_MAKEFILE) not found — set PROJECT_MAKEFILE"; exit 1; \
	fi; \
	sed 's|^$(BUMP_VAR)[[:space:]]*?*=.*|$(BUMP_VAR)  ?= '"$$latest"'|' \
	  $(PROJECT_MAKEFILE) > $(PROJECT_MAKEFILE).tmp; \
	if cmp -s $(PROJECT_MAKEFILE) $(PROJECT_MAKEFILE).tmp; then \
	  rm -f $(PROJECT_MAKEFILE).tmp; \
	  echo "could not find a $(BUMP_VAR) line in $(PROJECT_MAKEFILE)"; exit 1; \
	fi; \
	mv $(PROJECT_MAKEFILE).tmp $(PROJECT_MAKEFILE); \
	if [ -n "$(BUMP_SLUG)" ]; then \
	  for wf in $(WORKFLOW_GLOB); do \
	    [ -f "$$wf" ] || continue; \
	    sed 's|\($(BUMP_SLUG)/\.github/workflows/[A-Za-z0-9_.-]*\)@[^ 	]*|\1@'"$$latest"'|g' \
	      "$$wf" > "$$wf.tmp" && mv "$$wf.tmp" "$$wf"; \
	  done; \
	fi; \
	echo "$(BUMP_NAME) build $(BUMP_CUR) -> $$latest"
