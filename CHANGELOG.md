# Changelog

Maintained by [release-please](https://github.com/googleapis/release-please) from
Conventional Commits. Consumers pin exact versions, so every entry here is a
deliberate upgrade someone has to opt into with `make update-build`.

Note the local convention: a change to what `make check` accepts is a minor bump
at minimum, never a patch, because it can turn a previously-green project red.

## [0.9.0](https://github.com/tittle-xyz/go-shared-build/compare/v0.8.1...v0.9.0) (2026-07-30)


### Features

* add release-pr-guard reusable workflow ([#28](https://github.com/tittle-xyz/go-shared-build/issues/28)) ([15f751f](https://github.com/tittle-xyz/go-shared-build/commit/15f751f451563649016405834eca278015df2325))

## [0.8.1](https://github.com/tittle-xyz/go-shared-build/compare/v0.8.0...v0.8.1) (2026-07-27)


### Bug Fixes

* stop the secret scan flagging the shared build's own fixture ([#25](https://github.com/tittle-xyz/go-shared-build/issues/25)) ([6337950](https://github.com/tittle-xyz/go-shared-build/commit/633795077599cb629049149fefc25db195b14064))

## [0.8.0](https://github.com/tittle-xyz/go-shared-build/compare/v0.7.0...v0.8.0) (2026-07-26)


### Features

* run gitleaks in the gate, pinned as a tool ([#23](https://github.com/tittle-xyz/go-shared-build/issues/23)) ([e9ef4de](https://github.com/tittle-xyz/go-shared-build/commit/e9ef4de1d2ffd4c7fe794d8451aa164232a87897))

## [0.7.0](https://github.com/tittle-xyz/go-shared-build/compare/v0.6.1...v0.7.0) (2026-07-26)


### Features

* let a release publish an image and CLI binaries together ([#21](https://github.com/tittle-xyz/go-shared-build/issues/21)) ([b4cae83](https://github.com/tittle-xyz/go-shared-build/commit/b4cae832678754d89e5ad172e102882ec0d275c9))

## [0.6.1](https://github.com/tittle-xyz/go-shared-build/compare/v0.6.0...v0.6.1) (2026-07-26)


### Bug Fixes

* stop promising a rename re-runs the title check without the edited trigger ([#19](https://github.com/tittle-xyz/go-shared-build/issues/19)) ([2fb0503](https://github.com/tittle-xyz/go-shared-build/commit/2fb0503810a8f1a978b7101e2b0dc48df309d338))

## [0.6.0](https://github.com/tittle-xyz/go-shared-build/compare/v0.5.0...v0.6.0) (2026-07-26)


### Features

* block merges when the PR title is not a Conventional Commit ([#17](https://github.com/tittle-xyz/go-shared-build/issues/17)) ([f95633c](https://github.com/tittle-xyz/go-shared-build/commit/f95633c2275bee92760fda3bd3e03694d6cdd0e4))

## [0.5.0](https://github.com/tittle-xyz/go-shared-build/compare/v0.4.1...v0.5.0) (2026-07-26)


### Features

* let release-please author its PR with a supplied token ([#13](https://github.com/tittle-xyz/go-shared-build/issues/13)) ([0f44106](https://github.com/tittle-xyz/go-shared-build/commit/0f44106e4aa28c7e7294f3487cef8eaef82f7fb2))

## [0.4.1](https://github.com/tittle-xyz/go-shared-build/compare/v0.4.0...v0.4.1) (2026-07-26)


### Bug Fixes

* make the override-warning assertion able to fail ([#11](https://github.com/tittle-xyz/go-shared-build/issues/11)) ([3d19195](https://github.com/tittle-xyz/go-shared-build/commit/3d191956c9547d0edebe93b8d99c18742c5b72e1))

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
