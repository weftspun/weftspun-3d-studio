# RFD 0051: Model image for worldmirror2_reconstruct

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

See `DETAILS.md` for the model's memory, the `predict()` interface,
why there is no pose input, and how the splat becomes a USD payload.

## Related

RFD 0052 is the single-photo path. RFD 0033 records COLMAP. RFD 0053
gives the stage rule.
