# RFD 0052 details: the model, the interface, the X-flip, the viewport contract

## The model

| Property   | Value            |
| ---------- | ---------------- |
| Parameters | 1.1 B, estimated |
| bf16       | 2.2 GB           |
| Q4_K_M     | 0.61 GB          |
| Format     | bf16             |

## The interface

| Input       | Type | Default |
| ----------- | ---- | ------- |
| image       | Path | none    |
| max_splats  | int  | 500000  |
| seed        | int  | -1      |

## The X-flip belongs here, and only here

decisions/agent/DECISIONS.md records the rule from 2026-07-26. A
TripoSplat cloud takes an X-flip. A LingBot cloud does not, and RFD
0050 states that.

Apply the flip inside this Cog, and write the result already flipped.
A caller must never decide, because the two clouds then look alike and
the wrong one takes the flip.

## The viewport contract

RFD 0009 records the viewport. It loads splats through Spark, and it
must not use the XYZRGB point stride. That stride scatters a Gaussian
PLY.

The output PLY must therefore carry the Gaussian attributes and not a
bare point list. A point list would load, and it would look wrong.
