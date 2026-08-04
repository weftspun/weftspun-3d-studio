# RFD 0041: Cog for p3sam_mesh_segmentation

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

## The model

| Property   | Value             |
| ---------- | ----------------- |
| Parameters | 0.4 B, estimated  |
| bf16       | 0.8 GB            |
| Q4_K_M     | 0.22 GB           |
| License    | MIT               |
| Format     | bf16              |

## The interface

| Input          | Type  | Default |
| -------------- | ----- | ------- |
| mesh           | Path  | none    |
| segment_every_part | bool | false |
| max_parts      | int   | 32      |
| seed           | int   | -1      |

`segment_every_part` is the mode PartSAM and P3-SAM share. It returns
every part it finds, and it ignores `max_parts`.

## The output

`predict()` returns a `BaseModel`. It carries `labels`, which is one
integer per face, and `parts`, which is a list of GLB files.

A face-length integer array on a 210000 vertex mesh is large. Write it
as a JSON file, and not as an inline list. RFD 0033 gives the vertex
cap.

## Why the label array leads

A part label is stable input for the rig stage and for the remix
stage. A split mesh is not, because a later decimation renumbers the
faces. Give the caller the stable thing first.

## Related

RFD 0029 selects P3-SAM and PartSAM. RFD 0028 records why PartField
went. RFD 0008 records the trait remix that consumes the parts.
