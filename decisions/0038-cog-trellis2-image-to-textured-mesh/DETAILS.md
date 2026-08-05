# RFD 0038 details: the model, the interface, staging

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
