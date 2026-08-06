# RFD 0039: Model image for trellis2_image_mesh_painting

**State:** discussion
**Feature:** model packaging

## Problem

Mesh painting takes a mesh that exists and gives it a texture from an
image. It uses the same TRELLIS.2 weights as RFD 0038. A second copy
of those weights costs 8.0 GB and buys nothing.

## Decision

Build `FROM` the RFD 0038 image. Add a `predict.py`, and add no
weights. The model image is then about 40 MB, and not 8 GB.

See `DETAILS.md` for the model's shared-weight cost, the `predict()`
interface, and why the UV unwrap must not hide inside this model image.

## Related

RFD 0038 holds the weights. RFD 0036 gives the model image convention. RFD
0033 records the UV stage.
