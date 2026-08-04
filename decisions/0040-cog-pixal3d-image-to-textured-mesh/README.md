# RFD 0040: Cog for pixal3d_image_to_textured_mesh

**State:** discussion
**Feature:** model packaging

## Problem

Pixal3D is the image to 3D path in daily use. It writes a metal map
and a roughness map, which TRELLIS.2 does not.

Two records disagree with that practice. `DEFAULT_MODEL_BY_FEATURE` in
src/library/aiModelsCatalog.js selects TRELLIS.2, and the picker label
marks TRELLIS.2 as recommended. RFD 0026 then marks Pixal3D `unknown`.

The most used model therefore has no memory number. RFD 0027 sums
116.45 GB without it, thus that budget has a hole.

## Decision

Package Pixal3D first, and treat it as the primary image to 3D Cog.
Measure its parameter count before the build, because RFD 0027 cannot
close until that number exists.

Change the catalog default in a separate change. This RFD does not
edit code.

## The measurement

The count comes from the checkpoint, and not from a paper. Sum the
tensor shapes in each safetensors header.

```python
from safetensors import safe_open
n = 0
with safe_open(path, framework="pt") as f:
    for k in f.keys():
        s = f.get_slice(k).get_shape()
        n += 1
        for d in s:
            n *= d
```

Divide by 1e9 for the count in billions. Multiply that by 2 for the
bf16 weight in GB, per RFD 0025.

## The interface

| Input             | Type | Default |
| ----------------- | ---- | ------- |
| image             | Path | none    |
| texture_resolution| int  | 1024    |
| decimation_target | int  | 210000  |
| seed              | int  | -1      |

The output is not one file. A PBR result is a GLB plus its map set,
thus `predict()` returns a `BaseModel` and not a `Path`.

## Do not guess the memory

An invented number would enter RFD 0027 and move the residency budget.
The `unknown` mark is honest until the measurement runs.

## Related

RFD 0026 marks this model unknown. RFD 0027 holds the budget this
measurement closes. RFD 0038 packages the TRELLIS.2 alternative.
