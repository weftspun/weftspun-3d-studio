# RFD 0050: Cog for lingbot_map_environment_scan

**State:** prediscussion
**Feature:** model packaging

## Problem

LingBot-Map turns a walk video into a 1:1 metric twin of a room. It
runs two phases, and RFD 0026 marks its parameter count `unknown`.

The scale is the product. A twin that is 3 percent small is not a
twin. Every other model in the catalog may be wrong by a scale factor
and still be useful. This one may not.

## Decision

Model the two phases as a taskweft domain, and make the metric
calibration a guard and not a step.

Measure the parameter count before the build, as RFD 0040 does for
Pixal3D. This RFD stays in prediscussion until that number exists.

See `DETAILS.md` for the two phases, the gravity-alignment rule, the
metric gate, and what still blocks packaging.

## Related

RFD 0053 gives the stage format. RFD 0037 gives the convention.
RFD 0027 holds the budget this measurement closes.
