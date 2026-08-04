# RFD 0047: Cog for voxhammer_text_mesh_editing

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

## The model

| Property   | Value                             |
| ---------- | --------------------------------- |
| Parameters | 0. It shares the RFD 0038 weights |
| bf16       | 8.0 GB, the RFD 0038 cost         |
| License    | MIT                               |

## The interface

| Input       | Type | Default |
| ----------- | ---- | ------- |
| mesh        | Path | none    |
| instruction | str  | none    |
| region      | Path | none    |
| seed        | int  | -1      |

`region` is a mask. RFD 0028 records the supported mask list in
decisions/api/api.md.

## The unmasked region must not move

Inversion is lossy. A decode of an unedited latent does not give back
the input mesh exactly, thus a naive implementation moves vertices the
user never selected.

The domain states this as a guard. `a_decode` requires
`/have/preserved_outside`, and `a_splice` sets it by pasting the
original geometry back outside the mask.

That guard is the whole reason this model is a composite here.

## Layers make the edit reversible

RFD 0053 gives the rule. The edit is a sublayer over the source mesh,
thus a caller mutes the layer and gets the original back. A flat file
makes the edit permanent.

## Related

RFD 0038 holds the weights. RFD 0037 gives the composite convention.
RFD 0048 is the image variant. RFD 0053 gives the layer rule.
