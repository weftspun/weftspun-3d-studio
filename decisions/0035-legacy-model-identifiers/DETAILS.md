# RFD 0035 details: the identifier table and the two rules that stay

## The identifiers

| Model id                       | Task                         |
| ------------------------------ | ----------------------------- |
| trellis_text_to_textured_mesh  | Text to 3D                   |
| trellis_image_to_textured_mesh | Image to 3D (legacy)         |
| trellis_image_mesh_painting    | Image mesh painting (legacy) |
| trellis_text_mesh_painting     | Text mesh painting           |
| unirig_auto_rig                | Auto rig (template VRM)      |
| appearance_component_auto_rig  | Auto rig (appearance)        |
| creature_template_auto_rig     | Auto rig (creature)          |

## Two rules stay

TRELLIS v1 fails xformers on GB200-class GPUs. Avoid it on that
hardware tier, except for the multiview path.

UniRig is the only backend for the template VRM mode. SkinTokens
rejects that mode.
