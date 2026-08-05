# RFD 0072: GEM as teacher, RF-DETR Keypoint as student

**State:** discussion
**Scope:** RFD 0071's T-pose gate, RFD 0064's dataset

## Problem

RFD 0071 leaves two questions open. It needs a measured angle
tolerance, and it has none yet. RF-DETR Keypoint trains on COCO,
real photos, and RFD 0064's dataset is anime art, with no
human-labeled keypoint set for that domain.

## Decision

Use GEM-X (NVlabs) as a teacher. It reads monocular video or an
image, and it returns a 77-joint, full-body 3D pose in the SOMA
format RFD 0045's Kimodo already shares.

Run GEM once, offline, over two sets. Run it over a set of
known-good T-pose edits, and derive RFD 0071's tolerance from its 3D
joint angles. Run it over RFD 0064's dataset, and fine-tune RF-DETR
Keypoint, the student, on its output as pseudo-labels. The student
then learns the anime domain with no manual annotation.

GEM-X's code is Apache 2.0. Its weights carry the NVIDIA Open Model
License Agreement, which permits commercial use and derivative
models, and claims no ownership over outputs. See `DETAILS.md` for
the license terms in full, the joint-mapping step between GEM's 77
joints and RF-DETR's 17, and the open questions.

## Related

RFD 0071 is the gate this teaches. RFD 0069 selects RF-DETR and sets
the license-check precedent this RFD follows. RFD 0045 shares the
SOMA format GEM outputs. RFD 0064 gives the dataset GEM labels. RFD
0028 gives the license gate.
