# RFD 0049: Cog for weftspun_image_to_world

**State:** discussion
**Feature:** model packaging

## Problem

This entry builds an explorable world from one image. It runs
TripoSplat for the environment, and TRELLIS.2 for the props. RFD 0026
records its own parameter count as 0, because it owns no weights.

The two halves make different things. A splat is a radiance field, and
a prop is a mesh. One output file cannot hold both well.

## Decision

Model it as a taskweft domain over the two Cogs. `domain.ex` and
`problem.ex` in this folder hold it.

Compose the result as a USD stage. The splat is one layer, and each
prop is a reference under its own prim. RFD 0053 gives the rule, and
this model is the clearest case for it.

## The model

| Part       | Source   | bf16    |
| ---------- | -------- | ------: |
| TripoSplat | RFD 0052 | 2.2 GB  |
| TRELLIS.2  | RFD 0038 | 8.0 GB  |
| **total**  |          | 10.2 GB |

The two never need to be resident together. The domain carries
`a_load` and `a_unload`, thus the peak is 8.0 GB and not 10.2 GB.

## The interface

| Input          | Type | Default |
| -------------- | ---- | ------- |
| image          | Path | none    |
| prop_count     | int  | 0       |
| prop_prompts   | str  | ""      |
| seed           | int  | -1      |

`prop_count` of 0 gives the environment only. That is the common case,
and it must not pay for the TRELLIS.2 load.

## Why the planner earns its place

`prop_count` decides whether TRELLIS.2 runs at all. A method
alternative checks it, thus the plan for an environment-only job never
mentions the mesh model.

A script would load it and then skip it.

## Related

RFD 0052 gives the splat half. RFD 0038 gives the prop half. RFD 0053
gives the stage composition. RFD 0037 gives the convention.
