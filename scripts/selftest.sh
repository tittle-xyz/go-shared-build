#!/usr/bin/env bash
# Self-test for the shared build.
#
# Scaffolds a throwaway Go module in a temp directory, wires it to the *working
# tree* of this repo (not a published tag), and exercises the targets a real
# project depends on. Run it locally with ./scripts/selftest.sh; CI runs it on
# every push and pull request.
#
# The point: a target that is broken here can never reach a tagged release, and
# consumers only ever pin tagged releases.
set -euo pipefail

SB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0

check() {
  local name="$1"; shift
  if "$@" >"$WORK/out.log" 2>&1; then
    echo "  ok    $name"
    pass=$((pass + 1))
  else
    echo "  FAIL  $name"
    sed 's/^/          /' "$WORK/out.log" | tail -25
    fail=$((fail + 1))
  fi
}

# Asserts a target fails, for the cases where failing is the correct behaviour.
check_fails() {
  local name="$1"; shift
  if "$@" >"$WORK/out.log" 2>&1; then
    echo "  FAIL  $name (expected non-zero exit, got success)"
    fail=$((fail + 1))
  else
    echo "  ok    $name"
    pass=$((pass + 1))
  fi
}

echo "==> scaffolding a throwaway project against $SB_ROOT"
PROJ="$WORK/proj"
mkdir -p "$PROJ/cmd/demo"

cat >"$PROJ/go.mod" <<'EOF'
module example.com/demo

go 1.25.5
EOF

cat >"$PROJ/cmd/demo/main.go" <<'EOF'
// Command demo exists only to exercise the shared build.
package main

import "fmt"

var version = "dev"

func main() {
	if _, err := fmt.Println(Greet("world"), version); err != nil {
		panic(err)
	}
}

// Greet builds a greeting.
func Greet(name string) string { return "hello, " + name }
EOF

cat >"$PROJ/cmd/demo/main_test.go" <<'EOF'
package main

import "testing"

func TestGreet(t *testing.T) {
	if got := Greet("x"); got != "hello, x" {
		t.Fatalf("Greet() = %q", got)
	}
}
EOF

# Include the working tree directly. A real project clones a pinned tag into
# .build/ instead; SHARED_BUILD_DIR is what makes both work.
cat >"$PROJ/Makefile" <<EOF
APP  := demo
MAIN := ./cmd/demo

SHARED_BUILD_DIR := $SB_ROOT

include \$(SHARED_BUILD_DIR)/go.mk
EOF

cd "$PROJ"

echo "==> targets that must succeed"
check "help"            make help
check "version"         make version
check "build"           make build
check "test"            make test
check "test-race"       make test-race
check "cover"           make cover
check "fmt"             make fmt
check "fmt-check"       make fmt-check
check "vet"             make vet
check "tidy"            make tidy
check "tidy-check"      make tidy-check
check "lint"            make lint
check "tools-versions"  make tools-versions
check "outdated"        make outdated
check "check"           make check
check "install"         env GOBIN="$WORK/gobin" make install
check "run"             make run
check "clean"           make clean

echo "==> the built binary works and is version-stamped"
make build >/dev/null 2>&1
check "binary runs"     ./bin/demo
if ./bin/demo | grep -q "hello, world"; then
  echo "  ok    binary output"; pass=$((pass + 1))
else
  echo "  FAIL  binary output: $(./bin/demo)"; fail=$((fail + 1))
fi

echo "==> targets that must FAIL when the project is broken"
printf 'package main\nfunc  Bad( ) {}\n' >"$PROJ/cmd/demo/bad.go"
check_fails "fmt-check catches bad formatting" make fmt-check
make fmt >/dev/null 2>&1
check "fmt repairs it"  make fmt-check
rm -f "$PROJ/cmd/demo/bad.go"

# errcheck is the linter most likely to be silently disabled by a config typo,
# so prove it actually fires rather than trusting the config to be loaded.
cat >"$PROJ/cmd/demo/lintbait.go" <<'EOF'
package main

import "os"

func lintBait() {
	f, _ := os.Open("/dev/null")
	defer f.Close()
	os.WriteFile("/dev/null", nil, 0o600)
}
EOF
check_fails "lint catches an unchecked error" make lint
rm -f "$PROJ/cmd/demo/lintbait.go"

cat >>"$PROJ/go.mod" <<'EOF'

require github.com/spf13/pflag v1.0.9
EOF
check_fails "tidy-check catches an untidy go.mod" make tidy-check

echo "==> SHARED_SKIP_TARGETS lets a project keep its own target"
cat >"$PROJ/Makefile" <<EOF
APP  := demo
MAIN := ./cmd/demo

SHARED_SKIP_TARGETS := run

SHARED_BUILD_DIR := $SB_ROOT

include \$(SHARED_BUILD_DIR)/go.mk

.PHONY: run
run: ## the project's own run
	@echo "project run target"
EOF
if make run 2>&1 | grep -q "project run target"; then
  echo "  ok    skipped target uses the project's definition"; pass=$((pass + 1))
else
  echo "  FAIL  skipped target: $(make run 2>&1 | tail -2)"; fail=$((fail + 1))
fi
if make run 2>&1 | grep -qi "overriding commands"; then
  echo "  FAIL  Make warned about overriding commands"; fail=$((fail + 1))
else
  echo "  ok    no override warning"; pass=$((pass + 1))
fi

echo
echo "==> $pass passed, $fail failed"
[ "$fail" -eq 0 ]
