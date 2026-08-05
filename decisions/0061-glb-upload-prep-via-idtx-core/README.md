# RFD 0061: GLB upload prep moves to idtx_core, later

**State:** discussion
**Scope:** `thirdparty/3d_studio/src/library/glbCompress.js`, `thirdparty/fabric-flow-adapters/`

## Problem

`__tests__/prepareGlbForApiUpload.test.js` tested two functions,
`computeApiUploadSimplifyRatio` and `prepareGlbForApiUpload`, that
`glbCompress.js` never defined. `TaskManager.jsx`'s skintokens
auto-rig path imports `prepareGlbForApiUpload` at line 1163 and
awaits it, and the import threw since whenever that call site was
written. RFD 0023 first recorded this gap, and it stayed open
through RFD 0060's move.

The mesh a browser uploads today is prepared by `compressGlbBuffer`
in the same file, over `gltf-transform`: client-side Draco, Meshopt,
and WebP. RFD 0053 makes OpenUSD the internal format, the way
`.blend` is internal to Blender, and it names glTF only a
transmission format, converted at the boundary. GLB, Draco, and WebP
belong at that boundary. They do not belong as the mesh-prep
pipeline itself, which is what `compressGlbBuffer` is today.

## Decision

The upload-prep job belongs on `idtx_core`'s USD-native transport,
not on a second bespoke GLB pipeline in JavaScript.
`thirdparty/fabric-flow-adapters/flow/` already carries what that
job needs, and this repository's browser compression does not.

None of that is reachable from a browser today. See `DETAILS.md` for
what `idtx_core` carries, the three steps to reach it, the interim
stopgap in `glbCompress.js`, and a bug that stopgap's tests surfaced.

## Related

RFD 0023 first recorded the `prepareGlbForApiUpload` gap. RFD 0053
selects OpenUSD as the internal format this RFD defends. RFD 0057
tracks open work of this shape.
