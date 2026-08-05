# RFD 0060 details: the second move, why a real move, what stays, paths, verification

## The symlink attempt, and why it failed

The first attempt at moving `src/library/` left a symlink at
`src/library`. A working session found that symlink broke relative
imports inside the moved files. Vite resolves a symlink to its real
path before applying a relative import. So
`thirdparty/library/aiModelsCatalog.js`'s `import '../core/domain/catalog.js'`
resolved against `thirdparty/core/`, which does not exist, instead
of `src/core/`, which does. `resolve.preserveSymlinks: true` in
`vite.config.js` and `vitest.config.js` fixed it once. Then a direct
instruction reversed the symlink call: move the real files.

## The second move, in full

`weftspun_studio/` becomes the repository root. Everything that was
at the root — `src/`, `package.json`, `vite.config.js`, `index.html`,
`public/`, `native/`, `tests/`, and the JS toolchain's own
`scripts/*.mjs` files — moves to `thirdparty/3d_studio/`.
`decisions/`, `.github/`, and a small, named set of root-level
`scripts/` stay at the root, alongside `weftspun_studio/`'s promoted
`lib/`, `test/`, `config/`, `mix.exs`, `Dockerfile`, and `deploy/`.

New work happens at the root: in `lib/`, in
`thirdparty/3d_studio/src/core/`, or in
`thirdparty/3d_studio/src/chain/`. It composes with
`thirdparty/3d_studio/` through a port, per RFD 0023, or it does not
touch it.

## Why a real move, not a rewrite of every import

RFD 0057 says a sweep is the wrong shape for a large, low-value
change. "Convert one when its model is next worked on, and not in a
sweep," in RFD 0057's own words. RFD 0023 says the same rule for
`src/library/`. "A module moves when a port covers it, and not
before."

Neither RFD 0023's per-file rule, nor RFD 0057's no-sweep rule,
required rewriting relative imports inside the moved trees. `git mv`
preserves history. Every existing import between files that moved
together keeps its shape. Those files moved as one tree, not as 139
and then several hundred independent edits.

## What stays at the root, and why

**`decisions/`** — direct instruction. The RFD index documents both
`weftspun_studio` and the browser client. Splitting it would break
RFD 0000's DRY policy.

**`.github/`** — GitHub Actions only discovers workflows at the true
repository root. It cannot move.

**`.devcontainer/`** — RFD 0056's dev container, for the Elixir
side. `devcontainer.json` sets `privileged: true` and
`--cgroupns=host` specifically so Quadlet units can start inside it.
Removed in this session, ahead of a rebuild.

**Six `scripts/` files, at the time of this move** — `ci.sh`,
`deploy-weftspun-quadlet.sh`, `studio-test.sh`,
`check-elixir-parses.exs`, `ste-lint-decisions.py`,
`check-model-images.py`. `.pre-commit-config.yaml` named four of
these by path, and pre-commit hooks run from the repository root.

Every other file under the old `scripts/` moved to
`thirdparty/3d_studio/scripts/` instead. That set is the JS build
helpers, the DGX sync scripts, and the XR proxies. Those files read
and write that tree, not this one. RFD 0063 later deleted
`ste-lint-decisions.py`, leaving five.

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
`weftspun_studio/` prefix RFD 0058 wrote. `scripts/deploy-weftspun-quadlet.sh`
still syncs the whole repository to `/opt/weftspun/src`, and that
tree's root is this repository's root.

`package.json`'s `lint:ste` script read `../../scripts/ste-lint-decisions.py`
and `../../decisions/0*/README.md` at the time of this move, because
`package.json` lives two levels under the tree those two paths were
actually in. RFD 0063 later deleted that script and that npm entry.

`.pre-commit-config.yaml`'s `studio-test` hook matches
`^(lib|test|config)/.*\.exs?$|^mix\.exs$` now, in place of
`^weftspun_studio/.*\.exs?$`.

## Verified

`mix compile` and `mix test` ran clean from the new root, at the
time of this move: 100 of 105 tests passed, 5 excluded. The 5
failures were a pre-existing architecture mismatch, unrelated to
this move. `deps/taskweft_nif/priv/libtaskweft_nif.so` was an ARM
aarch64 binary, and this box is x86_64. `file` on the `.so`
confirmed it, and the failure was identical with or without the
swap. RFD 0057 records the later fix. All 105 tests pass now.

`npx vitest run` from `thirdparty/3d_studio/` resolves
`src/library/aiModelsCatalog.js`'s `import '../core/domain/catalog.js'`
correctly, now that `library/` is a real directory under `src/`
again, and not a symlink elsewhere. `src/core` and
`prepareGlbForApiUpload.test.js` together: 54 passed, the same 5
pre-existing `glbCompress.js` export failures RFD 0023 already
records, and no import-resolution failure.

## What this does not do

It does not fix the `prepareGlbForApiUpload` gap RFD 0023 already
records. That gap sits inside
`thirdparty/3d_studio/src/library/glbCompress.js` now, the same as
it sat inside `src/library/glbCompress.js` before.

It does not touch RFD 0023's `src/core/` / `src/chain/` split. Both
trees moved together, under `thirdparty/3d_studio/src/`, with every
import between them intact.
