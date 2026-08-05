#!/usr/bin/env bash
# One-step build: everything a CI run does, in the order it does it,
# runnable on a laptop. RFD 0059 backfills the decision this
# implements — Fowler's "Automate the Build" and "Make Your Build
# Self-Testing": one command, and it fails loud on the first broken
# piece.
#
# Usage: bash scripts/ci.sh
#
# Runs, in order: the JS test suite and production build, the Elixir
# suite against an ephemeral CockroachDB node, and both container
# images. Each step must pass before the next starts — the same
# ordering .github/workflows/main.yml uses, so a green run here means
# a green run there.
#
# RFD 0060 swapped the repo layout: weftspun_studio's content now
# sits at the repo root, and the JS app RFD 0060 calls thirdparty/
# lives at thirdparty/3d_studio/.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTAINER_ENGINE="${CONTAINER_ENGINE:-$(command -v podman || command -v docker || true)}"

step() { printf '\n=== %s ===\n' "$1"; }

# --- JS: test, then build -------------------------------------------

step "JS: install"
cd "$ROOT/thirdparty/3d_studio"
npm install --legacy-peer-deps

step "JS: unit tests"
npx vitest run

step "JS: production build"
VITE_PUBLIC_DEMO=1 npm run build

# RFD 0063 moves STE enforcement to the claude-ste-plugin's Stop hook,
# at write time. No repo-local lint:ste step runs in CI now — the
# script it called (scripts/ste-lint-decisions.py) is gone.

# --- Elixir: compile, then test against a throwaway CockroachDB -----

step "Elixir: deps"
cd "$ROOT/weftspun_studio"
export CC="${CC:-clang}" CXX="${CXX:-clang++}"
mix local.hex --force --if-missing
mix local.rebar --force --if-missing
mix deps.get

step "Elixir: compile"
mix compile --warnings-as-errors

step "Elixir: ephemeral CockroachDB"
mix weftspun.crdb install
COCKROACH_DATA_DIR="$(mktemp -d)"
export COCKROACH_DATA_DIR
mix weftspun.crdb >/tmp/weftspun-ci-crdb.log 2>&1 &
CRDB_PID=$!
cleanup() { kill "$CRDB_PID" 2>/dev/null || true; }
trap cleanup EXIT

for _ in $(seq 1 60); do
  (exec 3<>"/dev/tcp/127.0.0.1/26257") 2>/dev/null && { exec 3>&-; break; }
  sleep 1
done

step "Elixir: test suite"
mix test

kill "$CRDB_PID" 2>/dev/null || true
trap - EXIT

# --- Containers: build both images (no push) -------------------------

if [[ -n "$CONTAINER_ENGINE" ]]; then
  step "container: weftspun-crdb"
  "$CONTAINER_ENGINE" build -f deploy/Dockerfile.crdb -t localhost/weftspun-crdb:ci .

  step "container: weftspun"
  "$CONTAINER_ENGINE" build -f Dockerfile -t localhost/weftspun:ci .
else
  step "container: skipped, no podman or docker on PATH"
fi

step "CI: green"
