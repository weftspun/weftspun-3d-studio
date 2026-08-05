# RFD 0016 details: the inventory table

Every model below is a deep learning model. Each one runs as its own
Cog on Replicate, per RFD 0036. RFD 0033 lists the geometric
algorithms.

| Model id                        | Task                |
| -------------------------------- | ------------------- |
| trellis2_image_to_textured_mesh | Image to 3D         |
| trellis2_image_mesh_painting    | Image mesh painting |
| pixal3d_image_to_textured_mesh  | Image to 3D (PBR)   |
| p3sam_mesh_segmentation         | Mesh segmentation   |
| krea2_turbo_text_to_image       | Text to image       |
| qwen_q4_k_m_image_edit          | Image editing       |
| seethrough_layer_decomposition  | Image to layers     |
| kimodo_text_to_motion           | Text to motion      |
| skintokens_auto_rig             | Auto rig (full)     |
| voxhammer_text_mesh_editing     | Text mesh editing   |
| voxhammer_image_mesh_editing    | Image mesh editing  |
| weftspun_image_to_world         | Image to world      |
| lingbot_map_environment_scan    | Environment scan    |
| worldmirror2_reconstruct        | Photos to splat     |
| triposplat_image_to_splat       | Image to splat      |

## Client and external models

The avatar from photo task runs on AvatarSDK, which is an external
cloud service. The client stores the credentials in
VITE*AVATARSDK*\* variables. The WebXR expression tracking runs in the
browser. Neither one is part of the model catalog.
