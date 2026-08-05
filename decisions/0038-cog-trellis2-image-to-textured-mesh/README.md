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

See `DETAILS.md` for the model's memory and license, the `predict()`
interface, and why both flow stages stay in one container.

## Related

RFD 0036 gives the Cog convention. RFD 0053 gives the asset format.
RFD 0026 gives the memory. RFD 0002 records the pipeline stage this
model fills.
