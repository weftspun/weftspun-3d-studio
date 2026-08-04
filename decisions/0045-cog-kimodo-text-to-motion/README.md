# RFD 0045: Cog for kimodo_text_to_motion

**State:** discussion
**Feature:** model packaging

## Problem

Kimodo turns a sentence into motion. It emits SOMA, and the client
needs VRM humanoid tracks. The retarget between them is the hard part,
and it is not the model.

The model is small at 0.6 GB in bf16. The packaging risk is the
skeleton contract.

## Decision

Return the SOMA result and the VRM result as separate outputs. The
SOMA output is the model. The VRM output is a retarget, and a caller
that has its own rig wants the SOMA.

Do not hide the retarget. A single VRM output makes the model look
wrong when the retarget is what failed.

## The model

| Property   | Value            |
| ---------- | ---------------- |
| Parameters | 0.3 B, estimated |
| bf16       | 0.6 GB           |
| Q4_K_M     | 0.17 GB          |
| Format     | bf16             |

## The interface

| Input          | Type  | Default |
| -------------- | ----- | ------- |
| prompt         | str   | none    |
| duration_seconds | float | 4.0   |
| fps            | int   | 30      |
| target_rig     | Path  | none    |
| seed           | int   | -1      |

`target_rig` is optional. Without it the Cog returns SOMA only, and it
runs no retarget.

## The validation gate

RFD 0007 records the motion validation. A motion that leaves the floor
or that inverts a knee must fail here, and not in the viewport.

Run the validation inside this Cog, and return its verdict as a field.
A caller then knows the motion is unusable before it loads it.

## Related

RFD 0007 records the motion validation. RFD 0005 records the VRM
pipeline the retarget targets. RFD 0026 gives the memory.
