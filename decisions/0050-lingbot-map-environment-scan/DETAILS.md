# RFD 0050 details: the phases, the gravity rule, the metric gate, blockers

## The two phases

| Phase | Does                                   |
| ----- | ----------------------------------------|
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
| ----------------- | --------------------------------- |
| Parameter count  | RFD 0026 and RFD 0027 need it    |
| License          | RFD 0028 gates the ship          |
| Door metric source | The gate needs a known width   |
