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

## The two phases

| Phase | Does                                   |
| ----- | -------------------------------------- |
| A     | Tracks the camera through the walk     |
| B     | Reconstructs the surfaces              |

Phase B needs the poses from Phase A. The guard states that, thus no
plan may reverse them.

## The gravity rule

decisions/agent/DECISIONS.md records the rule from 2026-07-26. A
LingBot cloud is gravity aligned, and it must never take the
TripoSplat X-flip. It must never load through the XYZRGB point stride
either, because that stride scatters a Gaussian PLY.

The domain carries `orientation_mode` as a `:ref` variable with the
value `none`. A plan that sets anything else is wrong by construction.

## The metric gate

The door width is the check. A real door is a known width, thus a
scan that measures it wrongly has a wrong scale.

`a_calibrate` sets `/have/metric`, and `a_write_stage` requires it. A
scan that fails the gate produces no stage at all.

## What blocks the packaging

| Question         | Why it blocks                    |
| ---------------- | -------------------------------- |
| Parameter count  | RFD 0026 and RFD 0027 need it    |
| License          | RFD 0028 gates the ship          |
| Door metric source | The gate needs a known width   |

## Related

RFD 0053 gives the stage format. RFD 0037 gives the convention.
RFD 0027 holds the budget this measurement closes.
