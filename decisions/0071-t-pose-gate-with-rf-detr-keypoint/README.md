# RFD 0071: A T-pose gate, with RF-DETR's keypoint model

**State:** discussion
**Scope:** RFD 0043's output, RFD 0040's input

## Problem

RFD 0064's step 3 postpones RFD 0043, Qwen image edit, because the
edit must match a T-pose character pose. Nothing in the pipeline
checks whether an edited image reached that pose. RFD 0040
(Pixal3D) then spends mesh-generation compute on whatever RFD 0043
returns, pose-conforming or not.

## Decision

Gate RFD 0040's input on a T-pose check. Run RF-DETR's keypoint
model, the Apache 2.0 preview tier RFD 0069 already selects, over
each image RFD 0043 edits. Measure the joint positions it returns
against a T-pose target: arms near horizontal, legs together, spine
vertical.

Reject an image that fails the check, before it reaches RFD 0040.
A caller then retries RFD 0043 on a known-bad pose, and RFD 0040
never spends compute on one.

See `DETAILS.md` for the keypoint set, the tolerance this RFD does
not yet fix, and the open question of where the retry loop lives.

## Related

RFD 0064 names the T-pose requirement this RFD checks. RFD 0043 is
the edit this RFD gates. RFD 0040 is the stage this RFD protects.
RFD 0069 selects the RF-DETR tier and confirms its license.
