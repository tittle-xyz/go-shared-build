# go-shared-build — agent notes

Build tooling shared by every tittle-xyz Go project. **This repo is public** and
contains no Go code of its own — it is Makefiles, a lint config, and reusable
GitHub Actions workflows that other repositories pin and execute.

## The thing to understand before changing anything

Every change here runs in **every consuming project's CI**, some of it with
`contents: write` and `packages: write`. A target that works only on your machine
breaks other people's builds. Two rules follow:

1. **Run `./scripts/selftest.sh` before claiming a change works.** It scaffolds a
   throwaway Go module against the working tree and exercises every target,
   including asserting that `fmt-check`, `lint` and `tidy-check` *fail* on broken
   input. A lint config that silently stopped loading would otherwise look green.
2. **Nothing private goes in this repo.** Anything naming our infrastructure —
   clusters, namespaces, registries, deploy destinations — belongs in the private
   overlay `go-shared-build-internal`. Rule of thumb: if a stranger could use it
   unchanged, it belongs here.

## Layout

| File | Holds |
| --- | --- |
| `go.mk` | build, test, coverage, fmt, vet, lint, tidy, `check` |
| `tools.mk` | pinned tool versions and their install rules |
| `update.mk` | `update` (Go + deps) and `update-build` (the pins) |
| `docker.mk` | container targets, included only by services |
| `golangci.yml` | the shared lint config |
| `.github/workflows/` | four reusable workflows consumers call |
| `scripts/selftest.sh` | the test suite for all of the above |

## Makefile constraints

- **GNU Make 3.81 compatible** — that is what macOS ships. No `.ONESHELL`, no
  `$(file ...)`, no `!=` shell assignment.
- **Portable shell** — POSIX `sh`, and `sed`/`awk` that work under BSD *and* GNU.
  `sed -i` differs between them: write to a temp file and `mv`.
- **Every user-facing target needs a `## ` comment** — that comment is its help
  text, and a target without one is hidden from `make help`.
- CI runs the self-test on **both Ubuntu and macOS** precisely to catch the
  Make 3.81 / BSD sed differences.

## Workflow constraints

- **Third-party actions must be SHA-pinned.** A CI job fails the build on any
  unpinned `uses:`. Resolve real SHAs from the API — never guess one.
- A tag created by release-please's `GITHUB_TOKEN` does **not** trigger
  `on: release` or `on: push: tags`. That is why artifact builds are inlined
  behind the `release_created` gate rather than living in their own workflow.
- Under `workflow_call`, `github.ref` is the **caller's** ref. Anything deriving a
  version from it will silently be wrong; pass the release output explicitly.

## Versioning

Consumers pin exact versions and there is deliberately no moving `v1` alias, so
behaviour cannot change without a diff. Releases go through release-please from
Conventional Commits — nothing is tagged by hand.

**A change to what `make check` accepts is a minor bump at minimum**, never a
patch: it can turn a previously-green project red. Adding a linter is a `feat:`.
