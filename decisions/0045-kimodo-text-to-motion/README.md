# RFD 0045: Model image for kimodo_text_to_motion

**State:** discussion
**Feature:** model packaging

## Problem

Kimodo turns a sentence into motion. It emits SOMA, and the client
needs VRM humanoid tracks. The retarget between them is the hard part,
and it is not the model.

The model is small at 0.6 GB in bf16. The packaging risk is the
skeleton contract.

## Decision

Return the SOMA result and the VRM result as separate outputs. The
SOMA output is the model. The VRM output is a retarget, and a caller
that has its own rig wants the SOMA.

Do not hide the retarget. A single VRM output makes the model look
wrong when the retarget is what failed.

See `DETAILS.md` for the model's memory, the `predict()` interface,
and the motion validation gate this model image runs.

## Related

RFD 0007 records the motion validation. RFD 0005 records the VRM
pipeline the retarget targets. RFD 0026 gives the memory. RFD 0072
uses GEM, Kimodo's SOMA-X sibling, as a pose teacher.
