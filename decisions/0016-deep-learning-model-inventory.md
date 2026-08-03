# RFD 0016: Deep learning model inventory

**State:** published
**Feature:** model inventory

## Problem

The repository references many model identifiers. The catalog does
not record the type of each model. It does not record where each
model runs. A reader cannot tell a neural model from a geometric
algorithm.

## Decision

Keep the catalog as the source of truth for model identifiers.
Record the inventory in this RFD. The inventory lists each model,
its type, its task, and its runtime location.

The catalog lives at src/library/aiModelsCatalog.js. The live model
list filters the catalog when the API connects. This RFD records the
inventory at the time of writing. The catalog stays authoritative.

## Inventory

The repository uses 28 model identifiers. The table groups them by
task. The type column states whether the model is a deep learning
model or a geometric algorithm.

| Model id                                | Type                | Task                         | Runs on |
| --------------------------------------- | ------------------- | ---------------------------- | ------- |
| trellis2_image_to_textured_mesh         | Deep learning       | Image to 3D                  | DGX API |
| trellis2_image_mesh_painting            | Deep learning       | Image mesh painting          | DGX API |
| pixal3d_image_to_textured_mesh          | Deep learning       | Image to 3D (PBR)            | DGX API |
| p3sam_mesh_segmentation                 | Deep learning       | Mesh segmentation            | DGX API |
| krea2_turbo_text_to_image               | Deep learning       | Text to image                | DGX API |
| qwen_q4_k_m_image_edit                  | Deep learning       | Image editing                | DGX API |
| seethrough_layer_decomposition          | Deep learning       | Image to layers              | DGX API |
| kimodo_text_to_motion                   | Deep learning       | Text to motion               | DGX API |
| skintokens_auto_rig                     | Deep learning       | Auto rig (full)              | DGX API 
| instant_meshes_retopology               | Geometric algorithm | Mesh retopology              | DGX API |
| xatlas_uv_unwrapping                    | Geometric algorithm | UV unwrapping                | DGX API |
| voxhammer_text_mesh_editing             | Deep learning       | Text mesh editing            | DGX API |
| voxhammer_image_mesh_editing            | Deep learning       | Image mesh editing           | DGX API |

| Environment Model id                    | Type                | Task                         | Runs on |
| --------------------------------------- | ------------------- | ---------------------------- | ------- |
| weftspun_image_to_world                | Deep learning       | Image to world               | DGX API |
| lingbot_map_environment_scan            | Deep learning       | Environment scan             | DGX API |

| Splat Model id                          | Type                | Task                         | Runs on |
| --------------------------------------- | ------------------- | ---------------------------- | ------- |
| worldmirror2_reconstruct                | Deep learning       | Photos to splat              | DGX API |
| triposplat_image_to_splat               | Deep learning       | Image to splat               | DGX API |
| colmap_3dgs_reconstruct                 | Geometric algorithm | Photos to splat              | DGX API |

| Legacy Model id                          | Type                | Task                        | Runs on |
| --------------------------------------- | ------------------- | ---------------------------- | ------- |
| trellis_text_to_textured_mesh           | Deep learning       | Text to 3D                   | DGX API |
| trellis_image_to_textured_mesh          | Deep learning       | Image to 3D (legacy)         | DGX API |
| trellis_image_mesh_painting             | Deep learning       | Image mesh painting (legacy) | DGX API |
| trellis_text_mesh_painting              | Deep learning       | Text mesh painting           | DGX API |
| ~~hunyuan3dv21_image_to_textured_mesh~~ | Deep learning       | Image to 3D                  | DGX API |
| ~~hunyuan3dv21_image_to_raw_mesh~~      | Deep learning       | Image to raw mesh            | DGX API |
| ~~ultrashape_image_to_raw_mesh~~        | Deep learning       | Image to raw mesh            | DGX API |
| ~~hunyuan3dv21_image_mesh_painting~~    | Deep learning       | Image mesh painting          | DGX API |
| ~~unirig_auto_rig~~                     | Deep learning       | Auto rig (template VRM)      | DGX API |
| ~~appearance_component_auto_rig~~       | Deep learning       | Auto rig (appearance)        | DGX API |
| ~~creature_template_auto_rig~~          | Deep learning       | Auto rig (creature)          | DGX API |



## Client and external models

The avatar from photo task runs on AvatarSDK. AvatarSDK is an
external cloud service. It does not run on the DGX backend.
The client stores the credentials in VITE*AVATARSDK*\* variables.

The WebXR expression tracking runs in the browser. The native face
bridge relays face data when the browser lacks the API. These are
not part of the model catalog.

## Deleted models

The delete pass removes models that fail the commercial license
gate. The gate is the hard prerequisite in MODEL_LICENSES.md. Any
model shipped to paying users must clear commercial use.

PartField, PartPacker, and FastMesh fail the gate. Their weight
licenses permit non-commercial use only.

- PartField uses the NVIDIA license section 3.3.
- PartPacker uses the NVIDIA Source Code License section 3.3.
- FastMesh uses the S-Lab non-commercial license.

The pass tracks in issue #6. These models are not in the catalog.
The repository does not reference them in the UI. Their residual
references remain in docs/api/api.md. The delete pass removes them.

## Blocklisted models

The repository keeps a FOSS blocklist. Permissive licenses only.
The blocklist follows the complex condition licenses.

- hunyuan3dv21_image_to_raw_mesh uses the Tencent Community license.
  The license has territory and MAU rules. The blocklist removes it.
- ultrashape_image_to_raw_mesh inherits the Hunyuan pipelines. It
  inherits the Tencent rules. Review it with the same gate.
- hunyuan3dv21_image_to_textured_mesh uses the same Tencent license.
  It needs the same review.
- hunyuan3dv21_image_mesh_painting uses the same Tencent license.
  It needs the same review.
- CGAL uses the GPL license (commercial dual license). The project
  excludes GPL on license grounds. The blocklist removes it.

The FOSS replacement for raw mesh generation is TRELLIS.2. It uses
the MIT license. The catalog already carries it.

## FOSS replacements for deleted models

### PartField replacement (mesh segmentation)

The web search from August 2026 found three permissive candidates.
All use the MIT license.

- PartSAM (czvvd/PartSAM, ICLR 2026) segments parts on native 3D
  data. It supports a segment-every-part mode.
- HoloPart (VAST-AI/Research, MIT) completes occluded parts. It is a
  generative model.
- OmniPart (HKU-MMLab, SIGGRAPH Asia 2025) does part-aware 3D
  generation.

PartSAM is the primary recommendation. It trains on native 3D data,
so it works on AI-generated meshes. PartField needs clean mesh
connectivity, which generated meshes lack. PartSAM avoids that
weakness.

### FastMesh replacement (retopology)

The catalog already carries Instant Meshes. It uses the BSD-3
license. It is the primary replacement.

Other permissive options exist.

- QuadriFlow (MIT)
- meshoptimizer (MIT)
- trimesh_decimate (MIT)
- AutoRemesher (MIT)

The QuadWild Bi-MDF fork does not qualify. It uses the GPL-3 license.
The project excludes GPL projects on license grounds.

### PartPacker replacement (image to raw mesh)

The catalog already carries TRELLIS.2 and TRELLIS. Both use the
MIT license. Prefer them over PartPacker.

### Geometry refinement (trellis2cpp)

trellis2cpp (rms80/trellis2cpp) is a C++/ggml port of the TRELLIS.2
stage-1 geometry pipeline. It uses the MIT license. It turns an
image into a watertight mesh.

The richiejp pbr-textures fork adds geometry refinement and PBR
textures. It uses the MIT license. It runs on GPU backends through
ggml. It exports textured GLB without CUDA.

The fork adds CGAL as an optional build dependency. CGAL uses the
GPL license. The project excludes GPL on license grounds. Do not
make CGAL a required dependency.

The fork uses CGAL for alpha wrapping. Alpha wrapping turns a
defective triangle soup into a watertight mesh. The Polygon Mesh
Processing Library and Geogram do not implement alpha wrapping.
Keep CGAL optional, or drop the alpha wrap step from the build.
The fork still produces GLBs without CGAL.

Two permissive libraries cover the same goal.

- fTetWild (wildmeshing/fTetWild, MPL-2.0) turns a triangle soup
  into a tetrahedral mesh. Its boundary surface is watertight.
  It is heavier and volumetric. Use it when the strongest mesh
  guarantees matter. It is the preferred alpha wrap replacement.
- Manifold (elalish/manifold, Apache-2.0) repairs a triangle soup
  into a guaranteed manifold surface. It fits the embedded library
  design. Use it when a lighter option is acceptable.

One more permissive option exists.

- FOSSIL (szaghi/FOSSIL) implements an alpha wrap API. The project
  sells a BSD 2/3-Clause or MIT license for commercial use. The
  code is Fortran 2003+. The wrap is a single-pass octree MVP. It
  does not run the adaptive refinement loop yet.

FOSSIL fits a Fortran toolchain. It does not fit the C++ embedded
library design. fTetWild and Manifold stay the primary options.

Two wrap tools stay on the blocklist.

- ManifoldPlus (hjwdzh/ManifoldPlus) is non-commercial use only.
- wrapwrap (ipadjen/wrapwrap) uses the AGPL-3 license.

The 2026 shrink-wrap meshing paper (Scientific Reports) does not
release code. It does not count as an option.

## Rebuild path for alpha wrap

A clean-room rebuild on Geogram is viable. The algorithm comes from
the paper "Alpha Wrapping with an Offset" (ACM TOG 2022). The paper
is open access on HAL. It specifies the full algorithm.

Geogram provides the required primitives.

- Delaunay3d builds the 3D Delaunay triangulation with exact
  predicates. It supports the bounding box initialization.
- MeshFacetsAABB answers the distance, projection, and
  intersection queries.
- Expansion arithmetic keeps the combinatorial decisions exact.

The rebuild work is the traversal loop from the paper. It carves
outside cells and inserts Steiner points. It then extracts the
surface between inside and outside cells.

Use PMP for post-process cleanup. It decimates and remeshes the
wrap. It does not provide the carving structure.

FOSSIL proves the independent implementation. It uses an octree
variant instead of Delaunay. A Geogram-based build follows the
paper directly.

Remeshing and decimation stay in a separate stage. The Studio
pipeline already separates the retopology stage from the mesh
generation stage. trellis2cpp refines geometry. It does not replace
the retopology stage.

## References

- Catalog: src/library/aiModelsCatalog.js
- License audit: docs/MODEL_LICENSES.md in AlfaOmegaGrafx/3DAIGC-API
- Task types: src/library/taskManager.js
- Avatar rig: src/library/avatarPipelineCatalog.js
- Creature rig: src/library/creaturePipelineCatalog.js
- Avatar SDK: src/services/avatarSdkService.js
- Delete pass: issue #6

## Related

RFD 0004 catalogs the tasks that use these models. RFD 0006 records
the See-Through layer decomposition.
