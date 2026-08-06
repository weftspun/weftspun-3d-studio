# RFD 0050: Model image for lingbot_map_environment_scan

**State:** abandoned
**Feature:** model packaging

## Problem

LingBot-Map turns a walk video into a 1:1 metric twin of a room. It
runs two phases, and RFD 0026 marks its parameter count `unknown`.

The scale is the product. A twin that is 3 percent small is not a
twin. Every other model in the catalog may be wrong by a scale factor
and still be useful. This one may not.

## Decision

Do not package this model image. Abandon this line of work.

RFD 0064 turns the roadmap toward character concepts, and away from
environment scanning. The parameter-count measurement this RFD
waited on is no longer needed, because the model itself is out of
scope.

See `DETAILS.md` for the two phases, the gravity-alignment rule, and
the metric gate this RFD sketched before the pivot.

## Related

RFD 0064 records the pivot this RFD yields to. RFD 0053 gives the
stage format this RFD would have used. RFD 0037 gives the
convention. RFD 0027 held the budget this measurement would have
closed.
