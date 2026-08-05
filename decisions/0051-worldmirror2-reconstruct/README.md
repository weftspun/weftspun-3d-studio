# RFD 0051: Model image for worldmirror2_reconstruct

**State:** abandoned
**Feature:** model packaging

## Problem

WorldMirror 2.0 turns two or more photos into a Gaussian splat. It is
the multi-photo path, and RFD 0052 is the single-photo path.

`resolveSplatModelForPhotos` in src/library/aiModelsCatalog.js picks
between them by photo count. Two or more photos select this model.

## Decision

Do not package this model image. Abandon this line of work.

RFD 0064 turns the roadmap toward character concepts, and away from
multi-photo scene reconstruction. RFD 0052, its single-photo sibling,
is abandoned for the same reason.

See `DETAILS.md` for the model's memory and the `predict()`
interface this RFD sketched before the pivot.

## Related

RFD 0064 records the pivot this RFD yields to. RFD 0052 was the
single-photo path. RFD 0033 records COLMAP. RFD 0053 gives the stage
rule this RFD would have used.
