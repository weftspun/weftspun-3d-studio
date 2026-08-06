# RFD 0061 details: what idtx_core carries, the path there, the stopgap, a bug

`thirdparty/fabric-stage-runtime/` and `thirdparty/fabric-flow-adapters/`
are vendored as git subtrees, at `main` and `main-fabric`
respectively.

## What idtx_core carries that browser compression does not

`thirdparty/fabric-flow-adapters/flow/` already carries three things
this repository's browser compression lacks.

- **Content-defined chunking**, casync-compatible, SHA-512/256 chunk
  IDs (`idtx_chunker.h`). Two uploads of the same mesh, or two
  revisions that share most of their geometry, share most of their
  chunks. Nothing here gets resent.
- **USD-native mesh and VRM handling** (`idtx_import_usd.cpp`,
  `idtx_export_usd.cpp`, `idtx_vrm.cpp`), which composes with RFD
  0053's decision to make OpenUSD the internal format instead of
  round-tripping GLB at every stage.
- **AES + zstd transport** (`idtx_aes.cpp`, `idtx_transport.cpp`)
  already built for exactly this shape of problem. The same
  chunker/transport pair backs `multiplayer-fabric-godot`'s asset
  streaming.

## Why none of this is reachable yet

`flow/adapters/` holds three hosts: `godot/` (GDExtension), `unity/`
(P/Invoke), and `cli/`. It holds no fourth. Getting there needs:

1. An Elixir NIF (or Rustler-style binding) linking `idtx_core`
   through the ports it already exposes
   (`flow/ports/include/idtx_core/`), built against the OpenUSD
   `fabric-stage-runtime` already ships as `{:stage_runtime, "~>
   0.1.0-dev"}`. RFD 0053 already commits `weftspun_studio` to
   linking that build.
2. A `weftspun_studio` API route the browser uploads to, instead of
   whatever `image_to_textured_mesh`-style route it POSTs a GLB to
   today.
3. The browser call site swapped from `compressGlbBuffer` /
   `prepareGlbForApiUpload` to that route.

This RFD records the target and stops there. Building the NIF, the
port, the adapter, and the route is its own multi-session scope. It
is RFD 0057-style open work, not a task this RFD's Decision closes.

## The interim stopgap, in `glbCompress.js` today

This stopgap works in GLB, against RFD 0053's own rule that GLB
stays a transmission format and never the working format. It exists
only to unblock the failing test and the throwing import, until the
NIF adapter lets this path move to USD-native handling instead.

Two functions now exist, so the test the gap left red passes and
`TaskManager.jsx`'s import resolves.

`computeApiUploadSimplifyRatio(sourceVerts, sourceFaces, maxVertices, maxFaces, headroom = 0.85)`
gives the fraction of the *current* mesh to keep, driven by whichever
cap (verts or faces) needs the deeper cut. It returns `1` when both
are already under cap.

`prepareGlbForApiUpload(arrayBuffer, { maxVertices, maxFaces })`
passes a buffer through unchanged when it fits. Otherwise it `weld`s,
then loops `simplify` plus `dedup` plus `prune`, up to 5 passes.
Each pass re-measures against the cap, since `simplify`'s ratio is
relative to the current triangle count and not the source. It throws
if a rigged mesh (joints, weights, or morph targets, per
`documentNeedsSafeMode`) stays over the cap, since decimation skips a
rig to protect it. `TaskManager.jsx`'s call site relies on that throw
to drive its "too dense to auto-rig" warning.

Both are `gltf-transform` over the same `getIO()` pipeline
`compressGlbBuffer` already uses in this file. Nothing here is a
step toward the `idtx_core` path. Replace this whole block, and do
not extend it, once the NIF adapter exists.

## A bug this surfaced, unrelated to either path

`documentNeedsSafeMode` called `mesh.listTargets()`. Morph targets
live on `Primitive` in the installed `@gltf-transform/core`, not on
`Mesh`. `listTargets()` does not exist there, and every real call to
this function threw `TypeError: mesh.listTargets is not a function`.
`compressGlbBuffer` calls it unconditionally.

This broke the main compression path too, on every document with at
least one mesh, for as long as the check existed. No test exercised
either function against a real document until this RFD's test run
found it. Fixed: iterate primitives, and call `listTargets()` on
each.
