# RFD 0061: GLB upload prep moves to idtx_core, later

**State:** discussion
**Scope:** `thirdparty/3d_studio/src/library/glbCompress.js`, `thirdparty/fabric-flow-adapters/`

## Problem

`__tests__/prepareGlbForApiUpload.test.js` tested two functions,
`computeApiUploadSimplifyRatio` and `prepareGlbForApiUpload`, that
`glbCompress.js` never defined. `TaskManager.jsx`'s skintokens
auto-rig path imports `prepareGlbForApiUpload` at line 1163 and
awaits it; the import has been throwing since whenever that call
site was written. RFD 0023 first recorded this gap; it stayed open
through RFD 0060's move.

The mesh a browser uploads today is prepared by `compressGlbBuffer`
in the same file — client-side Draco + Meshopt + WebP, over
`gltf-transform`, one shot, no resume, no dedup against a peer's
copy of the same asset.

## Decision

The upload-prep job belongs on `idtx_core`'s transport, not on a
second bespoke JS pipeline. `thirdparty/fabric-flow-adapters/flow/`
already carries what that job needs and this repo's browser
compression does not:

- **Content-defined chunking**, casync-compatible, SHA-512/256 chunk
  IDs (`idtx_chunker.h`). Two uploads of the same mesh, or two
  revisions that share most of their geometry, share most of their
  chunks — nothing here is resent.
- **USD-native mesh and VRM handling** (`idtx_import_usd.cpp`,
  `idtx_export_usd.cpp`, `idtx_vrm.cpp`), which composes with RFD
  0053's decision to make OpenUSD the internal format instead of
  round-tripping GLB at every stage.
- **AES + zstd transport** (`idtx_aes.cpp`, `idtx_transport.cpp`)
  already built for exactly this shape of problem — the same
  chunker/transport pair backs `multiplayer-fabric-godot`'s asset
  streaming.

None of that is reachable from a browser today. `flow/adapters/`
holds three hosts — `godot/` (GDExtension), `unity/` (P/Invoke),
`cli/` — and no fourth. Getting there needs:

1. An Elixir NIF (or Rustler-style binding) linking `idtx_core`
   through the ports it already exposes (`flow/ports/include/idtx_core/`),
   built against the OpenUSD `fabric-stage-runtime` already ships as
   `{:stage_runtime, "~> 0.1.0-dev"}` — RFD 0053 already commits
   `weftspun_studio` to linking that build.
2. A `weftspun_studio` API route the browser uploads to instead of
   whatever `image_to_textured_mesh`-style route it POSTs a GLB to
   today.
3. The browser call site swapped from `compressGlbBuffer` /
   `prepareGlbForApiUpload` to that route.

This RFD records the target and stops there. Building the NIF, the
port, the adapter, and the route is its own multi-session scope —
RFD 0057-style open work, not a task this RFD's Decision closes.

## The interim stopgap, in `glbCompress.js` today

Two functions now exist, so the test the gap left red passes and
`TaskManager.jsx`'s import resolves:

- `computeApiUploadSimplifyRatio(sourceVerts, sourceFaces, maxVertices, maxFaces, headroom = 0.85)`
  — the fraction of the *current* mesh to keep, driven by whichever
  cap (verts or faces) needs the deeper cut. Returns `1` when both
  are already under cap.
- `prepareGlbForApiUpload(arrayBuffer, { maxVertices, maxFaces })` —
  passes a buffer through unchanged when it fits; otherwise `weld`s,
  then loops `simplify` + `dedup` + `prune` (up to 5 passes,
  re-measuring against the cap each time, since `simplify`'s ratio is
  relative to the current triangle count, not the source) until it
  fits. Throws if a rigged mesh (joints, weights, or morph targets —
  `documentNeedsSafeMode`) is still over the cap, since decimation
  skips a rig to protect it, and `TaskManager.jsx`'s call site relies
  on that throw to drive its "too dense to auto-rig" warning.

Both are `gltf-transform` over the same `getIO()` pipeline
`compressGlbBuffer` already uses in this file. Nothing here is a
step toward the `idtx_core` path — replace this whole block, not
extend it, once the NIF adapter exists.

## A bug this surfaced, unrelated to either path

`documentNeedsSafeMode` called `mesh.listTargets()`. Morph targets
live on `Primitive` in the installed `@gltf-transform/core`, not
`Mesh` — `listTargets()` does not exist there, and every real call
to this function has thrown `TypeError: mesh.listTargets is not a
function`. `compressGlbBuffer` calls it unconditionally, so this
broke the main compression path too, on every document with at least
one mesh, for as long as the check has existed. No test exercised
either function against a real document until this RFD's test run
found it. Fixed: iterate primitives, call `listTargets()` on each.

## Related

RFD 0023 first recorded the `prepareGlbForApiUpload` gap. RFD 0053
selects OpenUSD as the internal format and commits to linking
`fabric-stage-runtime`'s build. RFD 0057 tracks open work of this
shape. `thirdparty/fabric-stage-runtime/` and
`thirdparty/fabric-flow-adapters/` are vendored as git subtrees
(`git subtree add --squash`, `main` and `main-fabric` respectively).
