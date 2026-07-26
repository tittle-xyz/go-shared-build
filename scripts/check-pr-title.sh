#!/usr/bin/env bash
# Validate a pull request title as a Conventional Commit.
#
#   check-pr-title.sh "feat: add a thing"
#
# Why this gates merging rather than just warning: squash merges take the PR
# title as the commit subject and discard the prefixes on the individual commits.
# A plain-English title therefore leaves release-please nothing to parse — it
# finds no releasable change and skips the release, with no error anywhere. That
# has already cost one release, so it is a hard failure here.
#
# Exits 0 when the title is acceptable, 1 with an explanation when it is not.
set -euo pipefail

title="${1-}"

if [ -z "$title" ]; then
  echo "no PR title supplied" >&2
  exit 1
fi

# The Conventional Commits types we use. `build` and `ci` matter for Dependabot,
# which titles its PRs `build(deps): bump ...`.
TYPES='feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert'

# type(optional scope)optional-!: description
#
# Lowercase types only, and the description must be non-empty. A scope may
# contain letters, digits, dot, underscore, slash and hyphen — enough for
# `chore(main)`, `build(deps)`, `fix(internal/repo)`.
PATTERN="^(${TYPES})(\([a-z0-9._/-]+\))?!?: .+"

if printf '%s' "$title" | grep -qE "$PATTERN"; then
  echo "ok: $title"
  exit 0
fi

# GitHub's revert button generates `Revert "original title"`. Allowed on purpose:
# blocking an urgent revert on a title convention is the wrong trade. Note it
# produces no release, so the follow-up fix needs a conventional title of its own.
if printf '%s' "$title" | grep -qE '^Revert ".*"$'; then
  echo "ok (GitHub revert): $title"
  exit 0
fi

cat >&2 <<EOF
PR title is not a Conventional Commit:

    $title

Expected:  <type>[(scope)][!]: <description>
Types:     $(printf '%s' "$TYPES" | tr '|' ' ')

Examples:
    feat: add per-contract rounding
    fix(internal/repo): wrap the clone error with %w
    feat!: drop support for the old config format
    chore(deps): bump golangci-lint

This blocks the merge because squash merges use the PR TITLE as the commit
subject — the prefixes on your individual commits are discarded. Without a
conventional title, release-please parses nothing, finds no releasable change,
and silently skips the release.

Rename the pull request and this check will pass; no new push is needed --
provided your ci.yml subscribes to the `edited` event:

    on:
      pull_request:
        types: [opened, synchronize, reopened, edited]

Without `edited`, a rename does not re-run this check and the PR stays red until
an unrelated push. The templates ship with it.
EOF
exit 1
