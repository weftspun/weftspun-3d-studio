# RFD 0052: Model image for triposplat_image_to_splat

**State:** abandoned
**Feature:** model packaging

## Problem

TripoSplat turns one photo into a Gaussian splat. It is the
single-photo path, and RFD 0051 is the multi-photo path.

It is also half of RFD 0049, which builds an explorable world. That
makes it two callers with different needs from one model image.

## Decision

Do not package this model image. Abandon this line of work.

RFD 0064 turns the roadmap toward character concepts, and away from
single-photo scene reconstruction. RFD 0051, its multi-photo sibling,
and RFD 0049, its would-be caller, are abandoned for the same reason.

See `DETAILS.md` for the model's memory and the `predict()`
interface this RFD sketched before the pivot.

## Related

RFD 0064 records the pivot this RFD yields to. RFD 0051 was the
multi-photo path. RFD 0049 would have mounted these weights.
RFD 0009 records the viewport that would have loaded the result.
