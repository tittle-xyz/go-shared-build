# Security policy

## Reporting a vulnerability

Report privately through
[GitHub Security Advisories](https://github.com/tittle-xyz/go-shared-build/security/advisories/new),
not a public issue.

Expect an acknowledgement within a week. This is a personal project maintained by
one person, so please size your expectations accordingly — but anything affecting
consumers of this repo will be taken seriously and fixed promptly.

## What is in scope

This repo defines build tooling that runs in other repositories' CI, some of it
with `contents: write` and `packages: write`. In-scope issues are anything that
could let an attacker influence what runs there:

- A path to code execution in a consuming project's CI or on a developer machine
- An unpinned or tamperable dependency reference
- A workflow that grants more permission than it needs, or leaks a token
- Anything that would let a consumer's pinned version change without a diff

## What is not in scope

- Vulnerabilities in the pinned tools themselves (golangci-lint, GoReleaser) —
  report those upstream. If a pin here needs to move, an issue is fine.
- The absence of a linter or check you would prefer. That is a feature request.

## Supply-chain controls

- **Third-party actions are pinned to full commit SHAs.** CI fails if an unpinned
  `uses:` reference is introduced.
- **Dependabot** raises pin bumps as reviewable PRs, gated on the self-test.
- **Consumers pin exact versions** of this repo. There is deliberately no moving
  major-version alias, so a consumer's behaviour cannot change without a commit.
- **Tags are protected** and are never moved or deleted; fixes ship as new
  versions.
- **No secrets are stored here**, and `go-ci.yml` requests no secrets and only
  `contents: read`.

## A note on visibility

This repository is public by design. It contains no credentials, hostnames, or
infrastructure details, and being public is what allows public repositories and
pull requests from forks to build without a token — GitHub never passes secrets
to fork PRs.

Anything that names tittle-xyz infrastructure belongs in the private overlay,
`go-shared-build-internal`, not here.
