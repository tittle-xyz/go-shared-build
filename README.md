# go-shared-build

Shared build tooling for [tittle-xyz](https://github.com/tittle-xyz) Go projects:
Make targets, a lint config, pinned developer tools, and reusable GitHub Actions
workflows.

The point is **fix it once here, roll it out everywhere**. A project pins a
release; `make update-build` moves the pin forward. Nothing is copied into a
consuming project, so there is no vendored copy to drift.

It is public so that consuming it needs no configuration — see
[Security posture](#security-posture).

## Using it from a project

Start from [`go-cli-template`](https://github.com/tittle-xyz/go-cli-template) or
[`go-service-template`](https://github.com/tittle-xyz/go-service-template) — both
come wired up. To add it to an existing project, put this in its `Makefile`:

<!-- x-release-please-start-version -->
```make
APP  := myapp
MAIN := ./cmd/myapp

SHARED_BUILD_REPO ?= https://github.com/tittle-xyz/go-shared-build.git
SHARED_BUILD_REF  ?= v0.9.1
SHARED_BUILD_DIR  ?= .build

# Fetch the pinned build before the include is evaluated, so a fresh clone needs
# nothing but `make`.
_ := $(shell test -f $(SHARED_BUILD_DIR)/go.mk || { \
       git -c advice.detachedHead=false clone --quiet --depth 1 \
         --branch $(SHARED_BUILD_REF) \
         $(SHARED_BUILD_REPO) $(SHARED_BUILD_DIR) >&2 && \
       rm -rf $(SHARED_BUILD_DIR)/.git; })

include $(SHARED_BUILD_DIR)/go.mk
include $(SHARED_BUILD_DIR)/docker.mk   # services only
```
<!-- x-release-please-end -->

Add `.build/` and `.tools/` to `.gitignore`. The pin above always shows the
current release — release-please updates it here on every version bump.

Two details worth keeping. Fetching in a `$(shell …)` at parse time rather than as
a rule for the include avoids a spurious warning from GNU Make 3.81, which is what
macOS ships. And plain `include` rather than `-include` means a failed fetch is a
real error instead of a baffling "No rule to make target".

## What a project gets

Run `make` for the current list. The one to know is `make check` — `fmt-check`,
`tidy-check`, `vet`, `lint`, `test` — which is exactly what CI runs.

| Target | Does |
| --- | --- |
| `build` `install` `run` `clean` | Build into `bin/`, version-stamped via ldflags |
| `test` `test-race` `cover` `cover-html` | Test and coverage |
| `fmt` `fmt-check` `vet` `lint` `lint-fix` | Format and static analysis |
| `tidy` `tidy-check` | Module hygiene |
| `check` | The full pre-push gate |
| `secrets` `secrets-history` | Secret scanning with pinned gitleaks |
| `update` | Bump Go toolchain + dependencies, then verify |
| `update-build` | Move the build pins to their latest releases |
| `tools` `tools-versions` `tools-clean` | Pinned developer tooling |
| `snapshot` | Build a local release snapshot, publishing nothing |
| `docker-build` `docker-run` `image` | Containers (from `docker.mk`) |

## The two updates

Separate on purpose:

```sh
make update        # this project's Go toolchain and dependencies
make update-build  # the pinned build tooling
```

`make update` runs `go get go@latest`, `go get toolchain@latest`, `go get -u ./...`,
`go mod tidy`, then `make check` so a bad update fails immediately rather than in
CI. The *policy* for what updating means lives in [`update.mk`](update.mk) —
improve it once and every project inherits it.

`make update-build` finds the newest `v*` tag and rewrites **every** reference to
it in lockstep: the `Makefile` pin, the `uses:` refs in `.github/workflows/`, and
the private overlay if the project has one.

```diff
-SHARED_BUILD_REF  ?= v0.1.0
+SHARED_BUILD_REF  ?= v0.2.0
-    uses: tittle-xyz/go-shared-build/.github/workflows/go-ci.yml@v0.1.0
+    uses: tittle-xyz/go-shared-build/.github/workflows/go-ci.yml@v0.2.0
```

Bumping them together is deliberate: a project can never run v0.2.0 of the Make
targets against v0.1.0 of the CI workflow.

## Versioning and pinning

Consumers pin **exact versions** (`@v0.1.0`), never a floating major alias. There
is intentionally no moving `v0`/`v1` tag: a mutable ref means a consumer's
behaviour can change with no diff and no review. Every change arrives as a commit
you can read, applied when you run `make update-build`.

**This is 0.x, deliberately.** Nothing here has run in anger yet, and some of it
is expected to move — deploy targets are still to be designed, the readiness gate
default may need tuning, and migrating the first repos onto this will surface
things. A 1.0.0 would claim a stability that has not been earned. `0.x` is also
what every other repo in the org is on.

Because consumers pin exact versions, the usual "0.x means it might break you"
worry does not apply: nothing moves under you. Breaking changes bump the minor
version (`bump-minor-pre-major`), so `0.1.0 → 0.2.0` may well be breaking. Read
the [CHANGELOG](CHANGELOG.md) before bumping.

One local convention that outlives 0.x: **a change to what `check` accepts — a new
linter, a stricter gate — is a minor bump at minimum**, never a patch, because it
can turn a green project red.

## Pinned tools

Tool versions live in [`tools.mk`](tools.mk), not in any project's `go.mod`, so
projects carry no tool dependencies and a bump is one release here rather than N
pull requests.

Tools install into a shared cache (`~/.cache/tittle-xyz/go-tools` by default) with
the version in the filename, e.g. `golangci-lint-v2.12.2`. Two consequences:

- The cache is shared across every project on the machine, so building
  golangci-lint from source happens once, not once per repo.
- It lives outside `.build/`, which `make update-build` wipes — so a build bump
  that doesn't change tool versions costs nothing.

Set `TOOLS_DIR` to something repo-local if a project must be hermetic. Current
pins: `make tools-versions`.

## Migrating an existing repo

One thing bites every time: **the required status check names change.**

A repo's own CI usually has a job called `test` or `build-test`. Calling
`go-ci.yml` produces `ci / check` and `ci / readiness` instead. If branch
protection requires the old name, that check can never report again and every
pull request is blocked on a check that will never run — with no obvious error,
because nothing failed.

Check both places, because a repo can have either or both:

```sh
gh api repos/OWNER/REPO/branches/main/protection/required_status_checks \
  --jq '[.checks[].context]'
gh api repos/OWNER/REPO/rulesets --jq '.[] | {id, name, target}'
```

Then update them to the names the shared workflow actually emits:

```sh
gh api --method PATCH \
  repos/OWNER/REPO/branches/main/protection/required_status_checks \
  -f 'checks[][context]=ci / check'
```

Don't require `ci / readiness` in a repo that sets `readiness: false` — it
reports as skipped, and requiring a deliberately-disabled check is a trap for
the next person.

**Tell Dependabot to leave these refs alone.** Its `github-actions` ecosystem sees
`uses: tittle-xyz/go-shared-build/...@vX.Y.Z` and will happily bump it on its own
— putting the CI workflow on one version while the `Makefile` pin stays on
another. `make update-build` moves them together on purpose, so it should be the
only thing that touches them:

```yaml
  - package-ecosystem: github-actions
    directory: /
    ignore:
      - dependency-name: "tittle-xyz/go-shared-build/*"
```

Third-party actions still get updated normally.

A side benefit once migrated: check names are identical across every repo on the
shared build, so protection rules stop being per-repo trivia.

## Keeping a project's own target

When a project already defines a target this file also defines, Make warns about
overriding commands on every invocation. `SHARED_SKIP_TARGETS` leaves the shared
one undefined instead — set it *before* the include:

```make
SHARED_SKIP_TARGETS := run
include $(SHARED_BUILD_DIR)/go.mk

run: ## the project's own run
	...
```

Currently supported for `run` and `cover`. Use it sparingly: the value of the
shared build is that `make check` means the same thing everywhere. It exists for
established target names that predate the shared build.

## Reusable workflows

CI and release logic are reusable workflows, so they move with the pin too. A
caller is a handful of lines:

<!-- x-release-please-start-version -->
```yaml
name: ci
on:
  pull_request:
  push:
    branches: [main]
permissions:
  contents: read
jobs:
  ci:
    uses: tittle-xyz/go-shared-build/.github/workflows/go-ci.yml@v0.9.1
```
<!-- x-release-please-end -->

| Workflow | For |
| --- | --- |
| [`go-ci.yml`](.github/workflows/go-ci.yml) | Any Go project. Runs `make check`, optional race and build. |
| [`go-release-cli.yml`](.github/workflows/go-release-cli.yml) | CLIs. release-please + GoReleaser binaries and checksums. |
| [`go-release-image.yml`](.github/workflows/go-release-image.yml) | Services. release-please + container image to GHCR, plus CLI binaries with `binaries: true`. |
| [`release-tag.yml`](.github/workflows/release-tag.yml) | Repos with no build artifact. release-please only — what this repo uses. |

### Release PRs and the approval prompt

release-please creates its release pull request. If it does so as
`github-actions[bot]` — which is what happens with the default `GITHUB_TOKEN` —
GitHub will not run workflows for that PR without a human clicking approve on
each run. With required status checks enabled the PR is then *blocked*, not
merely unchecked. Repo settings cannot switch this off: the fork-PR approval
policy does not apply to private repos, and a release branch is not a fork.

So the release workflows accept an optional `RELEASE_PLEASE_TOKEN`. Given one,
release-please authors the PR as that identity, workflows run normally, and
release PRs get real CI signal:

```yaml
jobs:
  release:
    uses: tittle-xyz/go-shared-build/.github/workflows/go-release-cli.yml@v0.4.1
    secrets:
      RELEASE_PLEASE_TOKEN: ${{ secrets.RELEASE_PLEASE_TOKEN }}
```

Passed explicitly rather than with `secrets: inherit`, so the release job sees
exactly one secret instead of every secret the org has.

Unset, it falls back to `github.token` and everything still works — you just get
the approval prompt back. Two things to keep in mind:

- **A fine-grained PAT expires.** When it does, releases stop and the symptom is
  the approval prompt returning. A GitHub App installation token avoids the
  expiry entirely and is the better long-term answer.
- With a real token, a tag created by release-please **does** raise
  `push`/`release` events, unlike a `GITHUB_TOKEN` tag. The artifact builds here
  stay inlined behind the `release_created` gate anyway, so they work either way
  and don't depend on which token is in use.

### Shipping an image *and* CLI binaries

A repo that publishes both — `track` is the case — uses `go-release-image.yml`
with `binaries: true` rather than calling two workflows:

```yaml
jobs:
  release:
    uses: tittle-xyz/go-shared-build/.github/workflows/go-release-image.yml@v0.7.0
    with:
      binaries: true
    secrets:
      RELEASE_PLEASE_TOKEN: ${{ secrets.RELEASE_PLEASE_TOKEN }}
```

This has to be one workflow, not two: release-please can only run once per
release. Two callers would each try to cut it and fight over the tag.

## Security posture

This repo executes code in every consuming project's CI, some of it with
`contents: write` and `packages: write`. That is the blast radius worth defending,
and the controls are:

- **Third-party actions are pinned to commit SHAs**, never tags. A tag can be
  repointed by whoever owns it; a SHA cannot. [Dependabot](.github/dependabot.yml)
  keeps the pins fresh as reviewable PRs, and CI
  [asserts](.github/workflows/selftest.yml) that no unpinned `uses:` slips in.
- **Consumers pin exact versions** of this repo, and its tags are protected
  against being moved or deleted.
- **Least privilege** — `go-ci.yml` requests `contents: read` and no secrets. The
  release workflows request only what publishing needs.
- **No secrets live here.** It holds Make targets, a lint config, and workflow
  definitions. Nothing it contains ships in a binary or an image; it is read at
  build time only.

Being public is what lets public repos and fork pull requests build with no token
at all. The alternative — keeping it private — would have required a long-lived
org-wide PAT passed to workflows via `secrets: inherit`, which is a *larger*
exposure than a readable Makefile, and would still have broken fork PRs, since
GitHub never passes secrets to them.

Anything that names our infrastructure goes in the private overlay instead.

To report a vulnerability, see [SECURITY.md](SECURITY.md).

## The private overlay

Deploy destinations, cluster names, and internal registries live in a separate
private repo, `go-shared-build-internal`, which **includes** this one rather than
duplicating it. Private projects pin both:

```make
include $(SHARED_BUILD_DIR)/go.mk           # public core, first
include $(INTERNAL_BUILD_DIR)/internal.mk   # private overlay, last
```

`make update-build` bumps both pins together. Public projects use this core alone.

Rule of thumb for where something belongs: **if a stranger could use it unchanged,
it is not internal.**

## Developing this repo

It has no Go code of its own, so "does it work" means: does a real project built
against this working tree pass?

```sh
./scripts/selftest.sh
```

That scaffolds a throwaway module, wires it to the working tree, and exercises
every target — including asserting that `fmt-check`, `lint`, and `tidy-check`
actually **fail** on broken input. A lint config that silently stopped loading
would otherwise look like a green build. CI runs it on both Ubuntu and macOS,
because the Makefiles target GNU Make 3.81 and BSD `sed`, not just the GNU pair.

See [CONTRIBUTING.md](CONTRIBUTING.md).

## Releasing

Same flow as every other tittle-xyz repo: [release-please](https://github.com/googleapis/release-please)
driven by [Conventional Commits](https://www.conventionalcommits.org).

Consuming repos ship their own `release-please-config.json` and
`.release-please-manifest.json`; the reusable release workflows deliberately pass
no `release-type`, because doing so switches release-please into non-manifest mode
where those files are ignored — which silently produces a first release of 1.0.0
instead of the manifest's starting version.

Merge a `feat:` or `fix:` to `main` and release-please opens or updates a release
PR. Merging *that* bumps `version.txt`, writes `CHANGELOG.md`, creates the tag and
the GitHub Release — and refreshes the pinned versions in this README, so the
quickstart never goes stale.

Consumers then pick it up with `make update-build`.

**If you squash-merge, the PR title must be a Conventional Commit.** Squash takes
the PR title as the commit subject and throws away the individual commits'
prefixes, so a plain-English title leaves release-please with nothing to parse —
it finds no releasable change and skips the release without erroring.

`go-ci.yml` enforces this with a `pr-title` job, on by default. Add
**`ci / pr-title`** to the repo's required status checks and a bad title blocks
the merge instead of costing a release. Set `pr-title: false` to opt out.

**The caller must subscribe to `edited`**, or renaming a PR will not re-run the
check and a corrected title stays red until some unrelated push:

```yaml
on:
  pull_request:
    types: [opened, synchronize, reopened, edited]
```

A reusable workflow cannot set its caller's triggers, so this one line has to be
in each consumer's `ci.yml`. Both templates ship with it.

Two local conventions:

- **A change to what `make check` accepts is a minor bump at minimum**, never a
  patch — it can turn a passing project red. Use `feat:` for a new linter or a
  stricter gate.
- **No moving major alias.** There is no `v1` tag to chase; tags are protected
  against being moved or deleted, so a published version is immutable. Fixes ship
  as new versions.

## License

Apache 2.0. See [LICENSE](LICENSE).
