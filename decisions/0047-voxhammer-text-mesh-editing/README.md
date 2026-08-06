# RFD 0047: Model image for voxhammer_text_mesh_editing

**State:** discussion
**Feature:** model packaging

## Problem

VoxHammer edits a region of a mesh from a sentence. It carries no
weights of its own. It runs on the TRELLIS.2 backbone from RFD 0038,
and RFD 0026 records its parameter count as 0.

The edit is not one forward pass. It inverts the mesh to latents, it
edits inside the region, and it decodes. The region outside the mask
must come back unchanged, and that is the hard requirement.

## Decision

Derive from the RFD 0038 base image, and add no weights. Model the
three stages as a taskweft domain, because the guard that protects the
unmasked region belongs in the plan and not in a comment.

`domain.ex` and `problem.ex` in this folder hold it. RFD 0037
gives the convention.

See `DETAILS.md` for the model's shared-weight cost, the `predict()`
interface, the unmasked-region guard, and why layering makes the edit
reversible.

## Related

RFD 0038 holds the weights. RFD 0037 gives the composite convention.
RFD 0048 is the image variant. RFD 0053 gives the layer rule.
