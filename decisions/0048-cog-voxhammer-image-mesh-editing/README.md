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

See `DETAILS.md` for the mode branch, the model's shared-weight cost,
the `predict()` interface, and why the same preserve-outside guard
applies here too.

## Related

RFD 0047 holds the shared domain. RFD 0038 holds the weights. RFD 0053
gives the layer rule.
