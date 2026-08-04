# RFD 0026: bf16 memory per model

**State:** published
**Feature:** capacity planning

## Problem

The backend must decide which models stay resident. That decision
needs a number per model.

## Decision

Apply the rule from RFD 0025 to each catalog model. Treat the
estimated rows as an upper bound for planning.

The Source column says where each number comes from. `published` means
the model card states the count. `estimated` means this document
derives the count from the architecture. `unknown` means no count is
available yet.

## Weights per model

| Model id                        | Parameters | bf16 weights | Source    |
| ------------------------------- | ---------: | -----------: | --------- |
| qwen_q4_k_m_image_edit          |     27.0 B |      54.0 GB | published |
| krea2_turbo_text_to_image       |     16.9 B |      33.8 GB | estimated |
| seethrough_layer_decomposition  |      4.9 B |       9.8 GB | estimated |
| trellis2_image_to_textured_mesh |      4.0 B |       8.0 GB | estimated |
| trellis_image_to_textured_mesh  |      1.8 B |       3.6 GB | estimated |
| worldmirror2_reconstruct        |      1.2 B |       2.4 GB | estimated |
| triposplat_image_to_splat       |      1.1 B |       2.2 GB | estimated |
| skintokens_auto_rig             |      0.5 B |       1.0 GB | estimated |
| p3sam_mesh_segmentation         |      0.4 B |       0.8 GB | estimated |
| kimodo_text_to_motion           |      0.3 B |       0.6 GB | estimated |
| unirig_auto_rig                 |    0.125 B |      0.25 GB | estimated |
| pixal3d_image_to_textured_mesh  |    unknown |      unknown | unknown   |
| lingbot_map_environment_scan    |    unknown |      unknown | unknown   |
| voxhammer_text_mesh_editing     |          0 |            0 | published |
| voxhammer_image_mesh_editing    |          0 |            0 | published |
| weftspun_image_to_world         |          0 |            0 | composite |

VoxHammer carries no weights of its own. It edits with the TRELLIS.2
backbone, thus its cost is the TRELLIS.2 cost.
`weftspun_image_to_world` runs TripoSplat and then TRELLIS.2. Its cost
is the sum of those two. RFD 0033 covers the geometric algorithms,
which hold no weights at all.

The blocklisted Hunyuan models add 9.2 GB. The shape model holds
3.3 B parameters, which is 6.6 GB. The paint model holds 1.3 B
parameters, which is 2.6 GB.

## Related

RFD 0025 gives the arithmetic. RFD 0027 gives the totals and the
consequence. RFD 0030 breaks down the See-Through row.
