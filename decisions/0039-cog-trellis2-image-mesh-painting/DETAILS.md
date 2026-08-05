# RFD 0039 details: the model, the interface, the UV requirement

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
