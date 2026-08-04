# RFD 0033: Geometric algorithms in the catalog

**State:** published
**Feature:** model inventory

## Problem

The catalog mixes deep learning models and geometric algorithms. A
reader who plans memory cannot tell the two apart. They scale in
different ways.

## Decision

List the geometric algorithms apart from the neural models. RFD 0016
holds the neural models.

## The algorithms

| Model id                  | Task            | License |
| ------------------------- | --------------- | ------- |
| quadwild_retopology       | Mesh retopology | GPL-3   |
| instant_meshes_retopology | Mesh retopology | BSD-3   |
| xatlas_uv_unwrapping      | UV unwrapping   | MIT     |
| colmap_3dgs_reconstruct   | Photos to splat | BSD-3   |

All four run on the DGX API.

## How they scale

These algorithms hold no weights. Their memory scales with the mesh,
and not with a parameter count. A capacity plan must therefore use the
vertex budget, and not a bf16 figure.

src/library/aiModelsCatalog.js caps the mesh at 210,000 vertices. The
constant is `API_MAX_MESH_VERTICES`, and it matches the API upload cap.

## A license note

quadwild_retopology uses the GPL-3 license, which RFD 0028 excludes.
Instant Meshes is the permissive replacement, and RFD 0029 records the
other options.

## Related

RFD 0016 lists the neural models. RFD 0026 gives their bf16 memory.
