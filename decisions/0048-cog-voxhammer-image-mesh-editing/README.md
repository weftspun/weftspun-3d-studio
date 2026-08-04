# RFD 0048: Cog for voxhammer_image_mesh_editing

**State:** discussion
**Feature:** model packaging

## Problem

This is the image variant of RFD 0047. It edits a mesh region from a
reference image, and not from a sentence.

The two variants share every stage except the conditioning. Two
domains would drift, and a drifted guard is a moved vertex.

## Decision

Share the domain with RFD 0047. `voxhammer_mesh_editing` in
`0047-cog-voxhammer-text-mesh-editing/domain.ex` carries both. The
`mode` variable picks the branch.

```elixir
mode: %{type: :ref, init: %{conditioning: "image"}}
```

`apply_edit` holds one alternative per conditioning. Each one checks
`/mode/conditioning`, thus the planner takes exactly one.

This folder holds `problem.ex` only. RFD 0000 keeps one source per
design, and the domain is that source.

## The model

| Property   | Value                             |
| ---------- | --------------------------------- |
| Parameters | 0. It shares the RFD 0038 weights |
| bf16       | 8.0 GB, the RFD 0038 cost         |
| License    | MIT                               |

## The interface

| Input     | Type | Default |
| --------- | ---- | ------- |
| mesh      | Path | none    |
| reference | Path | none    |
| region    | Path | none    |
| seed      | int  | -1      |

`reference` is an image of what the region should become. It is not a
texture, and the model does not paste it.

## The same guard applies

`a_decode` requires `/have/preserved_outside`, exactly as in RFD 0047.
The conditioning changed, and the loss in the inversion did not.

## Related

RFD 0047 holds the shared domain. RFD 0038 holds the weights. RFD 0053
gives the layer rule.
