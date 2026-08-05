# RFD 0059: Continuous integration, in one step

**State:** discussion
**Scope:** `scripts/ci.sh`, `.github/workflows/main.yml`

## Problem

`.github/workflows/main.yml` ran `npm run test:anim-regression`.
`package.json` never defined that script. Every run of this job
failed at that line — CI has been red, or silently skipped, since
whenever that step was added.

It also tested one of three parts of this repository. `weftspun_studio/`
had no CI at all, and neither did the two Podman images RFD 0058
adds. A green build meant only that the JS side built.

## Decision

Follow Martin Fowler's ["Continuous
Integration"](https://martinfowler.com/articles/continuousIntegration.html):
one command builds and self-tests the whole system, a developer runs
it before committing, and the integration machine runs the identical
command. Two of his practices name the fault directly — "Automate the
Build" and "Make Your Build Self-Testing" — and a broken `npm run`
line that only ever ran on GitHub's machine is what happens when a
build isn't run by the person who last touched it.

`scripts/ci.sh` is that one command. `.github/workflows/main.yml`
installs the toolchains and calls it — nothing in the workflow
duplicates a step the script already runs.

## What the one step does

In order, stopping at the first failure:

1. `npm install`, `vitest run`, `npm run build` — the JS side.
2. `mix deps.get`, `mix compile --warnings-as-errors`, `mix test`
   against an ephemeral CockroachDB node the script starts and tears
   down itself (`mix weftspun.crdb`) — the Elixir side.
3. `podman build` (or `docker build`, whichever is on `PATH`) for
   both RFD 0058 images — no push, build only.

Each step must pass before the next runs. A JS test failure never
reaches the Elixir suite; a compile warning fails the build the same
as a test failure, per `--warnings-as-errors`.

## Why one script, not three CI steps

A step written only in YAML runs nowhere but GitHub's machine. This
repository's one broken CI step proves what that costs: nobody ran it
locally, so nobody noticed it never worked. A shell script runs on a
laptop and on a runner identically — `bash scripts/ci.sh` — so the
gap this RFD closes cannot reopen the same way.

`CONTAINER_ENGINE` picks `podman` first, falling back to `docker`,
because this project develops against Podman (RFD 0058) but GitHub's
runners ship Docker. The Dockerfiles are engine-agnostic; nothing in
either one assumes Podman.

## What this does not cover

Playwright (`test:e2e`) and the smoke scripts under
`test:anim-smoke` / `test:appearance-*` stay outside `scripts/ci.sh`.
They need a browser or a running dev server RFD 0059 does not stand
up. RFD 0058's `deploy-weftspun-quadlet.sh` stays outside it too —
continuous integration is not continuous deployment, and RFD 0058's
open firewall question means that script cannot pass on this host
yet regardless.

## Related

RFD 0058 gives the two container images this script builds. RFD 0020
gives the CockroachDB the Elixir step tests against.
