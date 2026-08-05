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

See `DETAILS.md` for the per-part memory, the `predict()` interface,
and why the planner earns its place over a fixed script.

## Related

RFD 0052 gives the splat half. RFD 0038 gives the prop half. RFD 0053
gives the stage composition. RFD 0037 gives the convention.
