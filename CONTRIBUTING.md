# Contributing

Thanks for looking. This is the build tooling behind the Go projects in the
tittle-xyz org, published because it is useful to read and costs nothing to share.

## The one thing to understand first

Every change here lands in **every consuming project** the next time it runs
`make update-build`. A target that works only in this repo, or only on your
machine, breaks other people's builds. That is why the self-test exists and why
it is thorough.

## Running the tests

```sh
./scripts/selftest.sh
```

It scaffolds a throwaway Go module in a temp directory, wires it to your working
tree, and exercises every target. It also asserts that `fmt-check`, `lint`, and
`tidy-check` **fail** on deliberately broken input — a lint config that quietly
stopped loading would otherwise look like a passing build.

CI runs it on Ubuntu and macOS. Both matter: macOS ships GNU Make 3.81 and BSD
`sed`, Linux has Make 4.x and GNU sed, and the Makefiles are written for the older
and stricter of each.

Workflows are linted with [actionlint](https://github.com/rhysd/actionlint), and a
CI job rejects any third-party `uses:` that is not pinned to a full commit SHA.

## House rules for Makefiles

- **GNU Make 3.81 compatible.** No `.ONESHELL`, no `$(file …)`, no `!=` shell
  assignment. If it needs Make 4, it does not go in.
- **Portable shell.** POSIX `sh`, and `sed`/`awk` invocations that work under both
  BSD and GNU. `sed -i` differs between them — write to a temp file and `mv`.
- **Every user-facing target carries a `## ` comment.** That comment is the help
  text; a target without one is hidden from `make help`.
- **Explain the non-obvious in a comment.** Much of this file set encodes a
  specific reason — why the fetch happens at parse time, why the tool cache sits
  outside `.build/`. Those reasons are the valuable part.

## What belongs here, and what does not

This repo is public. Anything that names tittle-xyz infrastructure — clusters,
namespaces, registries, deploy destinations — goes in the private overlay
`go-shared-build-internal` instead.

**If a stranger could use it unchanged, it belongs here.** If not, it does not.

## Commits and releases

[Conventional Commits](https://www.conventionalcommits.org) are required —
[release-please](https://github.com/googleapis/release-please) derives the version
and the CHANGELOG from them.

| Prefix | Effect |
| --- | --- |
| `fix:` | patch |
| `feat:` | minor |
| `feat!:` or `BREAKING CHANGE:` | major |
| `chore:` / `docs:` / `test:` | no release |

Merging to `main` opens or updates a release PR; merging that PR bumps
`version.txt`, writes `CHANGELOG.md`, tags, and publishes the GitHub Release.
Nothing is tagged by hand.

**Squash merges take the PR title as the commit subject, so the PR title has to
be a Conventional Commit too.** The prefixes on the individual commits are
discarded. Get this wrong and release-please parses nothing, finds no releasable
change, and skips the release — with no error anywhere:

```
commit could not be parsed: 9c9ab07 Migrate to go-shared-build (#38)
error message: Error: unexpected token ' ' at 1:8, valid tokens [(, !, :]
commits: 0
No commits for path: ., skipping
```

That is a real example: three properly-prefixed commits, a plain-English PR
title, and a release that silently never happened.

One local convention on top of semver: **anything that changes what `make check`
accepts is a minor bump at minimum**, because it can turn a passing project red.
Adding a linter is a `feat:`, not a `fix:`.

Tags are protected against being moved or deleted, so a published version is
immutable. Fixes ship as new versions.
