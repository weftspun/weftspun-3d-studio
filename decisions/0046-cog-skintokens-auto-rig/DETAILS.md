# RFD 0046 details: the model, the interface, UsdSkel, the joint order trap

## The model

| Property   | Value            |
| ---------- | ---------------- |
| Parameters | 0.5 B, estimated |
| bf16       | 1.0 GB           |
| Q4_K_M     | 0.28 GB          |
| Format     | bf16             |

## The interface

| Input     | Type | Default |
| --------- | ---- | ------- |
| mesh      | Path | none    |
| rig_mode  | str  | full    |
| seed      | int  | -1      |

`rig_mode` takes `skeleton`, `skin`, or `full`. It does not take
`template`. SkinTokens rejects template mode, and RFD 0035 records
that UniRig is the only backend for it.

## Why UsdSkel, and not a GLB skin

A GLB skin binds to one mesh. When the retopology stage later changes
the mesh, the skin breaks and the rig stage runs again.

A `UsdSkel` binding sits in its own layer. A new mesh layer below it
keeps the joint hierarchy, thus only the weights need a rebind.

## The joint order trap

VRM names its humanoid joints. USD does not, and it keeps an ordered
array. The mapping between them must live in the layer as metadata,
and not in the exporter.

An exporter that infers the mapping from joint names fails on any rig
that names a joint differently.
