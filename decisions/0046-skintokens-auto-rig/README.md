# RFD 0046: Model image for skintokens_auto_rig

**State:** discussion
**Feature:** model packaging

## Problem

SkinTokens is the default auto rig. It writes a skeleton and skin
weights for a mesh that has neither.

A rig is the clearest case for RFD 0053. The rig is an opinion about
an existing mesh, and a flat file forces the rig stage to rewrite the
mesh to carry it.

## Decision

Write the rig as a USD layer over the mesh layer. `UsdSkel` holds the
skeleton, the joint order, and the binding. The mesh layer below stays
untouched.

Emit VRM beside it, because the client needs VRM humanoid tracks.

See `DETAILS.md` for the model's memory, the `predict()` interface,
why `UsdSkel` beats a GLB skin, and the joint order trap between VRM
and USD.

## Related

RFD 0053 gives the layer rule. RFD 0035 records the template rig
split. RFD 0005 records the VRM pipeline.
