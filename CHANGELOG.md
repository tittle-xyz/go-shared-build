# Changelog

Maintained by [release-please](https://github.com/googleapis/release-please) from
Conventional Commits. Consumers pin exact versions, so every entry here is a
deliberate upgrade someone has to opt into with `make update-build`.

Note the local convention: a change to what `make check` accepts is a minor bump
at minimum, never a patch, because it can turn a previously-green project red.

## 0.1.0 (2026-07-26)

Initial release.

### Features

* `go.mk` — build, test, coverage, format, vet, lint and module-hygiene targets,
  with `check` as the single pre-push and CI gate.
* `tools.mk` — pinned developer tooling (golangci-lint v2.12.2, GoReleaser
  v2.12.7) installed into a version-keyed cache shared across projects.
* `update.mk` — `update` for the Go toolchain and dependencies; `update-build`
  for the build pins, rewriting the `Makefile` pin, the `uses:` refs in workflows
  and the private overlay pin together so they cannot drift apart.
* `docker.mk` — container build, run and image-reference targets for services.
* `golangci.yml` — shared lint configuration.
* Reusable workflows: `go-ci.yml`, `go-release-cli.yml`, `go-release-image.yml`
  and `release-tag.yml`.
* `scripts/selftest.sh` — scaffolds a throwaway module against the working tree
  and exercises every target, including asserting that `fmt-check`, `lint` and
  `tidy-check` fail on broken input. Runs on Ubuntu and macOS in CI.

### Security

* Third-party actions pinned to full commit SHAs, with CI rejecting any unpinned
  `uses:` reference and Dependabot raising bumps as reviewable pull requests.
* No moving major-version alias is published — consumers pin exact versions, so
  behaviour cannot change without a diff.
