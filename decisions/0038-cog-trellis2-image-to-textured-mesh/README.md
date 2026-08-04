# RFD 0038: Cog for trellis2_image_to_textured_mesh

**State:** discussion
**Feature:** model packaging

## Problem

TRELLIS.2 is the default for image to 3D. It is the backbone of four
other catalog entries. A Cog that packages it badly costs five models,
and not one.

## Decision

Package TRELLIS.2 once, and publish the image as the base for
RFD 0039, RFD 0047, RFD 0048, and RFD 0049. Those four add a
`predict.py`, and they add no weights.

## The model

| Property   | Value                          |
| ---------- | ------------------------------ |
| Parameters | 4.0 B, estimated               |
| bf16       | 8.0 GB                         |
| Q4_K_M     | 2.20 GB                        |
| License    | MIT                            |
| Format     | bf16, per RFD 0027             |

## The interface

`predict()` takes the image, the texture resolution, and the face
budget. It returns the base USD layer, and a GLB beside it. RFD 0053
gives that rule.

| Input             | Type | Default |
| ----------------- | ---- | ------- |
| image             | Path | none    |
| texture_resolution| int  | 1024    |
| decimation_target | int  | 210000  |
| seed              | int  | -1      |

`decimation_target` must not exceed 210000. That is
`API_MAX_MESH_VERTICES` in src/library/aiModelsCatalog.js, and it
matches the API upload cap. A larger mesh fails the next stage.

## Two stages, one container

The sparse structure flow runs first, and the SLat flow runs second.
Both stay in one Cog. They share the DINOv2 image encoder, thus a
split would load that encoder twice.

## Related

RFD 0036 gives the Cog convention. RFD 0053 gives the asset format.
RFD 0026 gives the memory. RFD 0002 records the pipeline stage this
model fills.
