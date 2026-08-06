# RFD 0041: Model image for p3sam_mesh_segmentation

**State:** discussion
**Feature:** model packaging

## Problem

P3-SAM segments a mesh into parts. It replaces PartField, which
RFD 0028 removed for a non-commercial weight license.

The model is small at 0.8 GB in bf16. The packaging risk is not the
memory. It is the output shape.

## Decision

Return the labels as data, and return the split meshes as files. A
caller that only needs the label array must not pay for a mesh split.

See `DETAILS.md` for the model's memory and license, the `predict()`
interface, the output shape, and why the label array leads.

## Related

RFD 0029 selects P3-SAM and PartSAM. RFD 0028 records why PartField
went. RFD 0008 records the trait remix that consumes the parts.
