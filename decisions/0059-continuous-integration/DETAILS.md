# RFD 0059 details: the steps, why one script, what it does not cover

## What the one step does

In order, stopping at the first failure:

1. `npm install`, `vitest run`, `npm run build`. The JS side.
2. `mix deps.get`, `mix compile --warnings-as-errors`, `mix test`
   against an ephemeral CockroachDB node the script starts and tears
   down itself (`mix weftspun.crdb`). The Elixir side.
3. `podman build` (or `docker build`, whichever is on `PATH`) for
   both RFD 0058 images. No push, build only.

Each step must pass before the next runs. A JS test failure never
reaches the Elixir suite. A compile warning fails the build the same
as a test failure does, per `--warnings-as-errors`.

## Why one script, not three CI steps

A step written only in YAML runs nowhere but GitHub's machine. This
repository's one broken CI step proves what that costs. Nobody ran
it locally, so nobody noticed it never worked. A shell script runs on
a laptop and on a runner identically, through `bash scripts/ci.sh`,
so the gap this RFD closes cannot reopen the same way.

`CONTAINER_ENGINE` picks `podman` first, falling back to `docker`,
because this project develops against Podman (RFD 0058), while
GitHub's runners ship Docker. The Dockerfiles are engine-agnostic.
Neither one assumes Podman.

## What this does not cover

Playwright (`test:e2e`) and the smoke scripts under
`test:anim-smoke` / `test:appearance-*` stay outside `scripts/ci.sh`.
They need a browser, or a running dev server this RFD does not stand
up.

RFD 0058's `deploy-weftspun-quadlet.sh` stays outside it too.
Continuous integration is not continuous deployment, and RFD 0058's
open firewall question means that script cannot pass on this host
yet regardless.
