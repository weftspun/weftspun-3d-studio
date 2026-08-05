# RFD 0060: A thirdparty/ reset

**State:** discussion
**Scope:** the repository root

## Problem

`src/library/` held 139 files and 56,376 lines. It predates RFD
0019's strangler fig and RFD 0023's `src/core/` split. 108 files
outside it still imported from it: tests, components, pages, the
chain modules, even one `src/core/adapters` file.

RFD 0023 already gives the correct move for each file: a module
crosses into `src/core/` or `src/chain/` when a port covers it, and
not before. That rule works file by file. It gave no place to put
the 108 files a port did not cover yet, and a reader could not tell,
from the layout alone, which code was the new minimal core and which
was the system RFD 0019 is stranglering.

The repository root carried the same problem at a larger scale.
`weftspun_studio/` sat as a subdirectory of the browser client's
tree, even though RFD 0019 makes it the API server the client is one
consumer of. The end-shape system was the guest; the system it is
replacing was the host.

## Decision

Two moves, one after the other.

**First**, `src/library/` to `thirdparty/library/`, with a symlink
left at `src/library`. A working session found that symlink broke
relative imports inside the moved files — Vite resolves a symlink to
its real path before applying a relative import, so
`thirdparty/library/aiModelsCatalog.js`'s `import '../core/domain/catalog.js'`
resolved against `thirdparty/core/`, which does not exist, instead
of `src/core/`, which does. `resolve.preserveSymlinks: true` in
`vite.config.js` and `vitest.config.js` fixed it once, then a direct
instruction reversed the symlink call: move the real files.

**Second**, `weftspun_studio/` becomes the repository root.
Everything that was at the root — `src/`, `package.json`,
`vite.config.js`, `index.html`, `public/`, `native/`, `tests/`, and
the JS toolchain's own `scripts/*.mjs` files — moves to
`thirdparty/3d_studio/`. `decisions/`, `.github/`, and a small,
named set of root-level `scripts/` stay at the root, alongside
`weftspun_studio/`'s promoted `lib/`, `test/`, `config/`, `mix.exs`,
`Dockerfile`, and `deploy/`.

Gall's law: a complex system that works grew from a simple system
that worked. The browser client is that working complex system.
Moving it to `thirdparty/` marks it a dependency, not the workspace.
New work happens at the root — in `lib/`, in `thirdparty/3d_studio/src/core/`,
or in `thirdparty/3d_studio/src/chain/`. It composes with
`thirdparty/3d_studio/` through a port, per RFD 0023, or it does not
touch it.

## Why a real move, not a rewrite of every import

RFD 0057 says a sweep is the wrong shape for a large, low-value
change: "convert one when its model is next worked on, and not in a
sweep." RFD 0023 says the same for `src/library/`: "A module moves
when a port covers it, and not before."

Neither RFD 0023's per-file rule nor RFD 0057's no-sweep rule
required rewriting relative imports inside the moved trees. `git mv`
preserves history and every existing import between files that moved
together keeps its shape, because they moved as one tree, not as 139
and then several hundred independent edits.

## What stays at the root, and why

**`decisions/`** — direct instruction. The RFD index documents both
`weftspun_studio` and the browser client; splitting it would break
RFD 0000's DRY policy.

**`.github/`** — GitHub Actions only discovers workflows at the true
repository root. It cannot move.

**`.devcontainer/`** — RFD 0056's dev container, for the Elixir
side; `devcontainer.json` sets `privileged: true` and
`--cgroupns=host` specifically so Quadlet units can start inside it.
Removed in this session, ahead of a rebuild.

**Six `scripts/` files** — `ci.sh`, `deploy-weftspun-quadlet.sh`,
`studio-test.sh`, `check-elixir-parses.exs`, `ste-lint-decisions.py`,
`check-model-images.py`. `.pre-commit-config.yaml` names four of
these by path, and pre-commit hooks run from the repository root.
Every other file under the old `scripts/` — the JS build helpers,
the DGX sync scripts, the XR proxies — moved to
`thirdparty/3d_studio/scripts/`, because they read and write that
tree, not this one.

**`LICENSE`, `TRADEMARKS`, `.formatter.exs`, `.gitattributes`,
`.pre-commit-config.yaml`** — repository-wide, not app-specific.
`.formatter.exs` now merges two input globs that used to be two
files: `decisions/**/*.{ex,exs}` (from the root's old file) and
`{mix,.formatter}.exs`, `{config,lib,test}/**/*.{ex,exs}` (from
`weftspun_studio/`'s).

## Paths this move touched

`WeftspunStudio.JsCatalog.@default_path`,
`test/catalog_parity_test.exs`, and `test/fact_store_test.exs` read
`thirdparty/3d_studio/src/library/aiModelsCatalog.js` now, in place
of `../src/library/aiModelsCatalog.js`.

`deploy/quadlet/weftspun.build` and `weftspun-crdb.build` read
`/opt/weftspun/src/Dockerfile` and
`/opt/weftspun/src/deploy/Dockerfile.crdb` now, in place of the
`weftspun_studio/` prefix RFD 0058 wrote — `scripts/deploy-weftspun-quadlet.sh`
still syncs the whole repository to `/opt/weftspun/src`, and that
tree's root is this repository's root.

`package.json`'s `lint:ste` script reads `../../scripts/ste-lint-decisions.py`
and `../../decisions/0*/README.md` now, because `package.json` lives
two levels under the tree those two paths are actually in.

`.pre-commit-config.yaml`'s `studio-test` hook matches
`^(lib|test|config)/.*\.exs?$|^mix\.exs$` now, in place of
`^weftspun_studio/.*\.exs?$`.

## Verified

`mix compile` and `mix test` run clean from the new root:
100 of 105 tests pass, 5 excluded. The 5 failures that were not
excluded are a pre-existing architecture mismatch —
`deps/taskweft_nif/priv/libtaskweft_nif.so` is an ARM aarch64
binary, and this box is x86_64 — unrelated to this move; `file` on
the `.so` confirms it, and the failure is identical with or without
the swap.

`npx vitest run` from `thirdparty/3d_studio/` resolves
`src/library/aiModelsCatalog.js`'s `import '../core/domain/catalog.js'`
correctly, now that `library/` is a real directory under `src/`
again and not a symlink elsewhere. `src/core` and
`prepareGlbForApiUpload.test.js` together: 54 passed, the same 5
pre-existing `glbCompress.js` export failures RFD 0023 already
records, no import-resolution failures.

## What this does not do

It does not fix the `prepareGlbForApiUpload` gap RFD 0023 already
records. That gap is inside `thirdparty/3d_studio/src/library/glbCompress.js`
now, same as it was inside `src/library/glbCompress.js` before.

It does not touch RFD 0023's `src/core/` / `src/chain/` split. Both
trees moved together, under `thirdparty/3d_studio/src/`, with every
import between them intact.

## Related

RFD 0019 gives the strangler fig this reset makes room for. RFD 0023
gives the per-file move rule this RFD does not replace. RFD 0057
tracks the `prepareGlbForApiUpload` gap and the taskweft_nif
architecture mismatch as open work. RFD 0058 gives the Quadlet paths
this RFD updates.
