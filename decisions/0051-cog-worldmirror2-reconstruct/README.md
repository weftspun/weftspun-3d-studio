# RFD 0051: Cog for worldmirror2_reconstruct

**State:** discussion
**Feature:** model packaging

## Problem

WorldMirror 2.0 turns two or more photos into a Gaussian splat. It is
the multi-photo path, and RFD 0052 is the single-photo path.

`resolveSplatModelForPhotos` in src/library/aiModelsCatalog.js picks
between them by photo count. Two or more photos select this model.

## Decision

Package it with a photo-count guard that matches the client. A single
photo must fail here with a clear reason, and it must not produce a
poor splat that looks like a model fault.

## The model

| Property   | Value            |
| ---------- | ---------------- |
| Parameters | 1.2 B, estimated |
| bf16       | 2.4 GB           |
| Q4_K_M     | 0.66 GB          |
| Format     | bf16             |

## The interface

| Input      | Type       | Default |
| ---------- | ---------- | ------- |
| images     | list[Path] | none    |
| max_splats | int        | 1000000 |
| seed       | int        | -1      |

`images` needs 2 or more entries. The Cog checks that count, thus the
contract holds when a caller bypasses the client.

## No pose input, and that is the point

COLMAP needs a pose solve before it reconstructs. RFD 0033 records it
as the geometric alternative at 3 or more photos.

WorldMirror needs no poses. It solves them inside the forward pass,
which is why it works at 2 photos where COLMAP fails.

Do not add a pose input to this Cog. A caller who has poses wants
COLMAP, and a caller who does not wants this.

## The splat is not a mesh

RFD 0053 makes USD the internal format, and a Gaussian splat has no
settled USD schema. Write the PLY as the payload, and reference it
from a prim with the transform and the bounds.

The stage then places the splat in the world. It does not try to
describe the Gaussians.

## Related

RFD 0052 is the single-photo path. RFD 0033 records COLMAP. RFD 0053
gives the stage rule.
