# Changelog

Maintained by [release-please](https://github.com/googleapis/release-please) from
Conventional Commits. Consumers pin exact versions, so every entry here is a
deliberate upgrade someone has to opt into with `make update-build`.

Note the local convention: a change to what `make check` accepts is a minor bump
at minimum, never a patch, because it can turn a previously-green project red.

## [0.4.0](https://github.com/tittle-xyz/go-shared-build/compare/v0.3.0...v0.4.0) (2026-07-26)


### Bug Fixes

* bump actions/cache from 4.3.0 to 6.1.0 ([#5](https://github.com/tittle-xyz/go-shared-build/issues/5)) ([97d1f15](https://github.com/tittle-xyz/go-shared-build/commit/97d1f15f16efae651176f9f7ece4a21d4859add8))
* bump actions/checkout from 4.4.0 to 7.0.1 ([#4](https://github.com/tittle-xyz/go-shared-build/issues/4)) ([e0fd824](https://github.com/tittle-xyz/go-shared-build/commit/e0fd8246240546c2199c211e8ca4fb6dc1001552))
* bump actions/setup-go from 5.6.0 to 7.0.0 ([#3](https://github.com/tittle-xyz/go-shared-build/issues/3)) ([ac109b2](https://github.com/tittle-xyz/go-shared-build/commit/ac109b218fadc1e131cd0f579c13a1a528b0c2b1))
* bump docker/build-push-action from 6.19.2 to 7.3.0 ([#1](https://github.com/tittle-xyz/go-shared-build/issues/1)) ([09db204](https://github.com/tittle-xyz/go-shared-build/commit/09db20422dc7ede7ee42931e6e4a59f61be7c08a))
* bump googleapis/release-please-action from 4.4.1 to 5.0.0 ([#2](https://github.com/tittle-xyz/go-shared-build/issues/2)) ([886128e](https://github.com/tittle-xyz/go-shared-build/commit/886128edbc34af65b4030b12cf8c68f346de66f3))


### Miscellaneous Chores

* release as 0.4.0, not a patch ([d5e82f7](https://github.com/tittle-xyz/go-shared-build/commit/d5e82f720c33c879ac9e88b2a50ebc17c2893491))

## [0.3.0](https://github.com/tittle-xyz/go-shared-build/compare/v0.2.0...v0.3.0) (2026-07-26)


### Features

* add SHARED_SKIP_TARGETS so a project can keep its own target ([8b8e297](https://github.com/tittle-xyz/go-shared-build/commit/8b8e2971cc0a530f8035e49fa6ba40c896c5b01d))

## [0.2.0](https://github.com/tittle-xyz/go-shared-build/compare/v0.1.0...v0.2.0) (2026-07-26)


### ⚠ BREAKING CHANGES

* let release-please config files take precedence over release-type

### Features

* let release-please config files take precedence over release-type ([2f90924](https://github.com/tittle-xyz/go-shared-build/commit/2f9092448fa54c888b6f1128f2ea672648bd06a4))

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
