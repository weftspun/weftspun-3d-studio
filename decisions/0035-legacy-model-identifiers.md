# RFD 0035: Legacy model identifiers

**State:** published
**Feature:** model inventory

## Problem

Seven model identifiers remain in the code after the TRELLIS.2 move.
A reader who sees them in a picker cannot tell them from the current
models.

## Decision

Keep the identifiers, and list them last in every picker.
`LEGACY_MODEL_IDS` in src/library/aiModelsCatalog.js drives that
order. Do not delete them, because saved tasks reference them.

## The identifiers

| Model id                       | Task                         |
| ------------------------------ | ---------------------------- |
| trellis_text_to_textured_mesh  | Text to 3D                   |
| trellis_image_to_textured_mesh | Image to 3D (legacy)         |
| trellis_image_mesh_painting    | Image mesh painting (legacy) |
| trellis_text_mesh_painting     | Text mesh painting           |
| unirig_auto_rig                | Auto rig (template VRM)      |
| appearance_component_auto_rig  | Auto rig (appearance)        |
| creature_template_auto_rig     | Auto rig (creature)          |

## Two rules stay

TRELLIS v1 fails xformers on GB200-class GPUs. Avoid it on the DGX,
except for the multiview path.

UniRig is the only backend for the template VRM mode. SkinTokens
rejects that mode.

## Related

RFD 0016 lists the active models. RFD 0005 records the avatar
pipeline. RFD 0028 records the license gate.
