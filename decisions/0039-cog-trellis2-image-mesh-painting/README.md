# RFD 0039: Cog for trellis2_image_mesh_painting

**State:** discussion
**Feature:** model packaging

## Problem

Mesh painting takes a mesh that exists and gives it a texture from an
image. It uses the same TRELLIS.2 weights as RFD 0038. A second copy
of those weights costs 8.0 GB and buys nothing.

## Decision

Build `FROM` the RFD 0038 image. Add a `predict.py`, and add no
weights. The Cog is then about 40 MB, and not 8 GB.

## The model

| Property   | Value                                 |
| ---------- | ------------------------------------- |
| Parameters | 0. It shares the RFD 0038 weights.    |
| bf16       | 8.0 GB, and that is the RFD 0038 cost |
| License    | MIT                                   |

## The interface

| Input             | Type | Default |
| ----------------- | ---- | ------- |
| mesh              | Path | none    |
| image             | Path | none    |
| texture_resolution| int  | 1024    |
| seed              | int  | -1      |

`mesh` takes GLB, and the API contract in decisions/api/api.md gives
`mesh_file_id` as the recommended handle. The Cog takes a file, thus
the adapter resolves the id before the call.

## The one hard part

The mesh arrives with its own UV layout, or with none. The painting
stage needs a layout. When the mesh has no UV set, run xatlas first.
RFD 0033 records xatlas, and it holds no weights.

Do not unwrap inside this Cog. A hidden unwrap makes the output depend
on a step the caller cannot see or repeat.

## Related

RFD 0038 holds the weights. RFD 0036 gives the Cog convention. RFD
0033 records the UV stage.
