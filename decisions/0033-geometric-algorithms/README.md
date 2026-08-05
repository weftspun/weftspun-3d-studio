# RFD 0033: Geometric algorithms in the catalog

**State:** published
**Feature:** model inventory

## Problem

The catalog mixes deep learning models and geometric algorithms. A
reader who plans memory cannot tell the two apart. They scale in
different ways.

## Decision

List the geometric algorithms apart from the neural models. RFD 0016
holds the neural models.

See `DETAILS.md` for the algorithm table, how they scale with mesh
size instead of parameter count, and a license note on
`quadwild_retopology`.

## Related

RFD 0016 lists the neural models. RFD 0026 gives their bf16 memory.
