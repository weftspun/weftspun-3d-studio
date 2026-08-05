# RFD 0052: Model image for triposplat_image_to_splat

**State:** discussion
**Feature:** model packaging

## Problem

TripoSplat turns one photo into a Gaussian splat. It is the
single-photo path, and RFD 0051 is the multi-photo path.

It is also half of RFD 0049, which builds an explorable world. That
makes it two callers with different needs from one model image.

## Decision

Package it once, and let RFD 0049 mount the same weights. The world
model image then adds no splat weights of its own.

See `DETAILS.md` for the model's memory, the `predict()` interface, why
the X-flip belongs only in this model image, and the viewport's Gaussian
PLY contract.

## Related

RFD 0051 is the multi-photo path. RFD 0049 mounts these weights.
RFD 0009 records the viewport that loads the result.
