# RFD 0052: Cog for triposplat_image_to_splat

**State:** discussion
**Feature:** model packaging

## Problem

TripoSplat turns one photo into a Gaussian splat. It is the
single-photo path, and RFD 0051 is the multi-photo path.

It is also half of RFD 0049, which builds an explorable world. That
makes it two callers with different needs from one Cog.

## Decision

Package it once, and let RFD 0049 mount the same weights. The world
Cog then adds no splat weights of its own.

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

## Related

RFD 0051 is the multi-photo path. RFD 0049 mounts these weights.
RFD 0009 records the viewport that loads the result.
