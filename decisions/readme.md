# 🧩 Supported 3DAIGC Modules

Task types in the **New Task** panel (`TaskManager.jsx`), backed by [3DAIGC-API](https://github.com/AlfaOmegaGrafx/3DAIGC-API) on DGX Spark (`:7842`). Live model list: `GET /api/v1/system/models` — mirrored in [`src/library/aiModelsCatalog.js`](src/library/aiModelsCatalog.js).

| Task                         | API feature                                  | Example models (DGX, Jun 2026)                                           |
| ---------------------------- | -------------------------------------------- | ------------------------------------------------------------------------ |
| Text to 3D                   | `text_to_textured_mesh`                      | TRELLIS                                                                  |
| Image to 3D                  | `image_to_textured_mesh`                     | **TRELLIS.2** (recommended), Pixal3D (PBR), Hunyuan3D-2.1                |
| Image to Raw Mesh            | `image_to_raw_mesh`                          | Hunyuan3D-2.1, UltraShape                                                |
| Mesh painting (text / image) | `text_mesh_painting` / `image_mesh_painting` | TRELLIS.2, Hunyuan                                                       |
| Mesh segmentation            | `mesh_segmentation`                          | P3-SAM                                                                   |
| Mesh retopology              | `mesh_retopology`                            | AutoRemesher (default), Instant Meshes, Trimesh Decimate                 |
| Mesh UV unwrapping           | `uv_unwrapping`                              | xatlas                                                                   |
| Mesh editing (text / image)  | `text_mesh_editing` / `image_mesh_editing`   | VoxHammer                                                                |
| Auto rigging                 | `auto_rig`                                   | **SkinTokens** (full GLB, recommended), UniRig (template VRM)            |
| Text to Motion (Kimodo)      | `text_to_motion`                             | **Kimodo SOMA-RP-v1.1** → studio motion JSON → VRM / rigged GLB playback |
| Image to Gaussian Splat      | `image_to_splat`                             | TripoSplat (1 photo), WorldMirror 2.0 (2+), COLMAP (3+)                  |
| Image to World               | `image_to_world`                             | `weftspun_image_to_world` (splat env + optional TRELLIS.2 props)         |
| Avatar from Image            | client pipeline                              | TRELLIS.2 mesh → UniRig template rig → GLB                               |
| Avatar From Photo            | client only                                  | AvatarSDK (not 3DAIGC-API)                                               |

**Also shipped (client + API):**

- **Multi-image input** — primary + up to 7 reference photos on splat, world, and avatar tasks ([`docs/MULTI_IMAGE_SPLAT_ROADMAP.md`](docs/MULTI_IMAGE_SPLAT_ROADMAP.md))
- **Publish RP1 / OMB validate** — mesh jobs → spatial fabric via MSF Map Service ([`docs/SPATIAL_FABRIC_INTEGRATION.md`](docs/SPATIAL_FABRIC_INTEGRATION.md))
- **Kimodo text-to-motion** — animation bar prompt → SOMA motion job → viewport playback on VRM and rigged GLB ([`KimodoMotionPromptBar.jsx`](src/components/KimodoMotionPromptBar.jsx), [`kimodoMotionLoader.js`](src/library/kimodoMotionLoader.js))

**Not in UI:** “Part completion” (legacy upstream docs only). **License-blocked** on commercial tiers: PartField, PartPacker, FastMesh — see [3DAIGC-API `MODEL_LICENSES.md`](https://github.com/AlfaOmegaGrafx/3DAIGC-API/blob/main/docs/MODEL_LICENSES.md).

## Gaussian splats (3DGS)

Gaussian splats live in **this app** — same `SceneManager` viewport as VRM and mesh workflows, not a separate product. **Generation** runs on DGX via [3DAIGC-API](https://github.com/AlfaOmegaGrafx/3DAIGC-API); **viewing** uses [Spark.js](https://sparkjs.dev/) (`sparkSplatManager.js`, `@sparkjsdev/spark`) in the main Three.js scene.

### Shipped today

| Capability                     | Client                                                    | API (DGX)                                                                  |
| ------------------------------ | --------------------------------------------------------- | -------------------------------------------------------------------------- |
| Splat preview in viewport      | `SplatMesh` alongside VRM/meshes                          | `POST /api/v1/splat-generation/image-to-splat`                             |
| **1 photo** → splat            | Task Manager multi-select (primary photo)                 | **TripoSplat**                                                             |
| **2+ photos** → splat          | Same; mark best front view as **Primary**                 | **WorldMirror 2.0** (COLMAP fallback at 3+)                                |
| World package load             | **World Library** + `worldSceneLoader.js`                 | `POST /api/v1/world-generation/image-to-world` (`weftspun_image_to_world`) |
| **Walk / XR environment scan** | Task Manager **Environment Scan**                         | `POST /api/v1/world-generation/environment-scan` (LingBot-Map)             |
| Env-scan Phase A → Spark       | Auto when `refine_to_3dgs`                                | Isotropic Gaussians from point cloud                                       |
| Env-scan Phase B train         | Separate or `train_3dgs: true`                            | `POST /train-3dgs` / `env_scan_gsplat_train` (7–10k steps)                 |
| Avatar + optional splat        | **Avatar from Image** + “Gaussian splat preview” checkbox | TRELLIS.2 mesh + UniRig template rig + optional TripoSplat                 |
| Multi-image uploads            | `multiImageInput.js` on splat / world / avatar tasks      | `image_file_id` + `reference_image_file_ids` (up to 8 total)               |

Task types: **Image to Gaussian Splat**, **Image to World (splat + props)**, **Environment Scan** in the New Task panel (`TaskManager.jsx`).

### What's not done yet

- **Splat-only world RP1** — World Library **RP1** needs mesh props in the manifest; pure Gaussian environments need a prop-generation path for OMB publish
- **Env-scan x402 SKUs** — Phase A vs Phase B billing + frame-budget upsell (monetization roadmap v3.3.7)
- **Gaussian-VRM / RGBAvatar body pipelines** — scan-based full-body avatars and highest-fidelity head attachment; separate from viewport TripoSplat preview (not the same code path as `image-to-splat`).

### Where it lives (architecture)

```text
[DGX 3DAIGC-API]  TripoSplat, WorldMirror/COLMAP, image-to-world, LingBot env-scan A/B, avatar mesh/rig jobs
       ↓
[Weftspun3DStudio /]  SceneManager — one renderer, one WebXR session, VRM + tools
       ↓                  SparkRenderer + SplatMesh (LingBot: orientationMode none)
```

`/xr` remains an **IWSDK lab** for grab/locomotion regression; the **main app** (`/`) runs IWSDK Option A on SceneManager — distance/proximity grab (trigger), grip → context menu / pan, thumbstick locomotion — alongside loaded splat worlds and VRM.

**Further reading**

- [Multi-image splat & avatar roadmap](docs/MULTI_IMAGE_SPLAT_ROADMAP.md) — 1 vs 2–8 photo routing
- [NVIDIA XR AI + 3DAIGC (DGX)](docs/NVIDIA_XR_AI_INTEGRATION.md) — voice VLM → mesh jobs on Galaxy XR
- [Dev machine topology](docs/DEV_MACHINE_TOPOLOGY.md) — Surface + DGX Spark roles, incremental sync, Galaxy XR URLs
- [World package format](docs/WORLD_PACKAGE.md) — splats, props, env-scan metric calibration
- [LingBot environment scan (API)](https://github.com/AlfaOmegaGrafx/3DAIGC-API/blob/main/docs/LINGBOT_MAP_ENVIRONMENT_SCAN.md) — Phase A/B, gravity, door metric
- [Spatial fabric / RP1](docs/SPATIAL_FABRIC_INTEGRATION.md) — Task Manager vs World Library publish
- [Avatar pipeline (client)](docs/AVATAR_PIPELINE.md) — avatar-from-image, optional splat preview, Arc2Avatar direction
- [Avatar pipeline (API)](https://github.com/AlfaOmegaGrafx/3DAIGC-API/blob/main/docs/AVATAR_PIPELINE.md) — endpoints, template rig, splat-generation

## ✨ Applications Features

### Open3DStudio Features

- Multiple rendering modes (Solid/Rendered/WireFrame/Skeleton/PartColorize)
- Task management with progress and history
- Multi-format support: GLB, GLTF, OBJ, FBX, VRM, DAE, STL
- File uploading: uploading images / meshes for later processing
- Basic 3D model viewing and manipulation
- All locally deployed, it's scalable and easy to add a feature/model both at the frontend and backend

### Weftspun3DStudio Features

- **WebXR Support**: Full VR/AR experiences with floor anchoring (main app via `SceneManager`)
  - VR mode with virtual sky backgrounds
  - AR mode with pass-through transparency
  - **Samsung Galaxy XR** (Chrome WebXR) as primary on-device XR target
  - Floor-aligned reference spaces for proper positioning
  - **WebXR expression tracking** when the browser exposes `expression-tracking` (VRM blink / mouth)
  - **Native face relay** when it does not — companion APK + dev-server ingest (see [OpenXR face tracking](docs/OPENXR_FACE_TRACKING_ANDROID_XR.md))
- **Gaussian splats (3DGS)**: Spark.js splat rendering in the main viewport (`SceneManager`); TripoSplat, WorldMirror, COLMAP, **LingBot Environment Scan** (Phase A/B), and world packages from **3DAIGC-API**; **WebXR grab + locomotion on `/`** (distance/proximity grab, thumbstick move/turn) with worlds + VRM in one session — see [Gaussian splats (3DGS)](#gaussian-splats-3dgs)
- **Spatial fabric (RP1 / OMB)**: **Publish RP1** on completed mesh tasks; **Validate OMB tier** on GLB export; explore in Open Metaverse Browser–compatible fabrics — [`docs/SPATIAL_FABRIC_INTEGRATION.md`](docs/SPATIAL_FABRIC_INTEGRATION.md)
- **XR AI panel**: `XrAiPanel` + `xrHubConfig.js` — in-app hub status and handoff to DGX **xr-ai** / MCP (parallel to voice-only stack)
- **WebGPU Rendering**: Automatic WebGPU detection with WebGL fallback
- **Advanced Post-Processing**: SSAO (Screen Space Ambient Occlusion), Bloom effects, FXAA anti-aliasing
- **Spatial Audio**: PositionalAudio support for immersive audio experiences
- **Core3D Integration**: Access to thousands of 3D models, materials library, AI-powered design generation
- **Shared 3D Viewer**: Unified viewing system for Weftspun3DStudio
- **Universal3DViewer**: Smart wrapper that auto-detects application mode
- Enhanced rendering and performance optimizations
- All Open3DStudio features included

### Weftspun3DStudio Avatar & VRM Features

- **VRM Character Creation**: Create and customize VRM avatars with trait-based system
- **Avatar Structure**: Base body VRM avatar is **soulbound** (non-transferable); clothing, hair, and accessories are equippable layers (see [Modder getting-started](docs/docs/Modders/getting-started.md)—base body layer 0)
- **Trait System**: Mix and match character components (body, clothing, hair, accessories, etc.)
- **Drag & Drop Customization**: Overwrite textures and models by dragging files into the browser
- **Animation Support**: Full animation system with Mixamo integration, **Kimodo text-to-motion**, bone remapping, and animation blending
- **Facial Expressions**: Blend shapes, lip sync, eye tracking, and automatic blinking
- **VRM Export**: Optimized VRM export with texture atlasing and mesh merging
- **Batch Processing**: Generate multiple VRMs from manifest.json files
- **Manifest-Driven Workflows**: Programmatic avatar assembly using JSON configuration
- **Character Optimization**: One-click optimization reducing models to single draw calls
- **Model Bridge**: Seamless import/export between Core3D designs and avatar/VRM workflows

## 🏗️ Architecture

### Key Components

#### Weftspun3DStudio Avatar Components

- `Scene3D`: Main 3D viewport with Three.js integration
- `TaskManager`: Handles AI generation tasks and progress tracking
- `FileUpload`: Drag & drop file upload with format validation
- `RenderModeSelector`: Switch between different rendering modes
- `APIStatus`: Monitor API connection and configure endpoints
- `SceneManager`: Core 3D scene orchestration (WebGL-based)

- `SceneManager`: Enhanced with WebGPU, WebXR, and post-processing support
- `Shared3DViewer`: Unified 3D viewer for both applications
- `Universal3DViewer`: Smart wrapper that auto-detects application mode
- `Core3DViewer`: Core3D design workflow integration
- `Core3DPanel`: Core3D API integration UI
- `Core3DContext`: Core3D state management
- `Core3DService`: Core3D API communication
- All Open3DStudio components with enhanced capabilities

- `CharacterManager`: Core character management with VRM support
- `Weftspun3DStudioBridge`: Legacy bridge class for GLB import into avatar workflows (internal API name)
- Uses `Shared3DViewer` and `Universal3DViewer` (developed by Weftspun3DStudio)
- `AnimationManager`: Handles character animations and bone remapping
- `BlinkManager`: Automatic eye blinking system
- `LookAtManager`: Eye tracking and head movement
- `EmotionManager`: Facial expression and blend shape management

### State Management

- `taskStore`: Manages AI generation tasks, progress, and history
- `sceneStore`: Handles 3D scene state, models, and rendering modes
- `SceneContext`: 3D scene and rendering state with SceneManager integration
- `Core3DContext`: Core3D API integration for design workflows

## 🎨 Features

### Weftspun3DStudio Features

- **3D Rendering Modes**: Solid, Rendered, Wireframe, Skeleton, Part Colorize
- **File Support**: GLB, GLTF, OBJ, FBX, DAE, STL, VRM formats
- **Images**: JPG, PNG, BMP, TGA (for image-to-3D workflows)
- **AI Workflows**: Text-to-3D, Image-to-3D, Image-to-Raw-Mesh, Mesh Painting, Segmentation, Retopology, UV Unwrapping, VoxHammer Editing, Auto Rigging, Image-to-Splat, Image-to-World, Avatar-from-Image

- **WebXR Features**:
  - **VR Mode**: Immersive virtual reality with floor-anchored content
  - **AR Mode**: Augmented reality with pass-through transparency
  - **Floor Anchoring**: Automatic model positioning at floor level
  - **Reference Spaces**: Support for `bounded-floor`, `local-floor`, `local`, and `viewer` spaces
  - **Android XR**: Optimized for Samsung Galaxy XR and other Android XR devices
  - **Background Management**: Virtual sky for VR, transparent pass-through for AR
- **WebGPU Rendering**: Automatic WebGPU detection with WebGL fallback
- **Advanced Post-Processing**: SSAO, Bloom effects, FXAA anti-aliasing
- **Spatial Audio**: PositionalAudio support for immersive audio experiences
- **Core3D Integration**:
  - Access to thousands of 3D models
  - Advanced material and texture library
  - AI-powered design generation
  - High-quality model exports
- All Open3DStudio features included

Open3DStudio was the original foundation of this project, providing core 3D AIGC capabilities with WebGL rendering. The [Three.js WebGPU & WebXR Migration Guide](docs/THREEJS_WEBGPU_WEBXR_MIGRATION.md) documents the evolution from Open3DStudio's WebGL-only SceneManager to Weftspun3DStudio's enhanced rendering stack. Open3DStudio features include:

- Basic 3D AIGC workflows and model processing
- WebGL-based rendering
- File format support and import/export capabilities
- Task management and progress tracking

- [Spatial fabric / RP1](docs/SPATIAL_FABRIC_INTEGRATION.md) - Publish to OMB-compatible spatial fabric
- [Multi-image splat roadmap](docs/MULTI_IMAGE_SPLAT_ROADMAP.md) - Primary + reference photos for splat/avatar
- [Avatar pipeline (client)](docs/AVATAR_PIPELINE.md) - Photo → rigged GLB/VRM, optional splat preview, key client files
- [IWSDK Option A Migration Blueprint](docs/IWSDK_OPTION_A_MIGRATION_BLUEPRINT.md) - IWSDK → main app migration; Spark world building stack
- [IWSDK Integration](docs/IWSDK_INTEGRATION.md) - Meta Immersive Web SDK (`/xr` route, Galaxy XR testing, optional PC emulator)
- [OpenXR Face Tracking (Android XR)](docs/OPENXR_FACE_TRACKING_ANDROID_XR.md) - Native face relay when Chrome lacks expression-tracking
- [Android XR Face Bridge APK](native/android-xr-face-bridge/README.md) - Companion app build and Chrome handoff
- [Webcam / Avatar Control](docs/WEBCAM_AVATAR_CONTROL.md) - Desktop webcam + XR expression paths
- [WebXR Floor Anchoring & Backgrounds](docs/XR_MODE_FLOOR_ANCHORING_AND_BACKGROUNDS.md) - XR implementation details
- [HTTPS Setup Guide](docs/HTTPS_SETUP.md) - WebXR development setup
- [Dev machine topology & sync cheat sheet](docs/DEV_MACHINE_TOPOLOGY.md) - Surface vs DGX roles, incremental sync, cross-sync prevention
- [Three.js WebGPU & WebXR Migration](docs/THREEJS_WEBGPU_WEBXR_MIGRATION.md) - Technical migration guide
- [VR Positioning](docs/VR_POSITIONING.md) - VR positioning configuration
- [AR Floor Anchoring Fix](docs/AR_FLOOR_ANCHORING_FIX.md) - AR implementation details
- [Android XR Floor Anchoring](docs/ANDROID_XR_FLOOR_ANCHORING.md) - Android XR compatibility
- [Shared 3D Viewer System](src/components/Shared3DViewer_README.md) - Unified viewer documentation
- [Core3D Integration](src/components/Core3D_README.md) - Core3D API integration guide
- [Quickstart](docs/docs/quickstart.md) - Getting started with avatar traits and VRM
- [Create an Avatar](docs/docs/General/create-an-avatar.md) - Avatar creation guide (includes programmatic/wallet-driven goals)
- [Optimize Avatars](docs/docs/General/optimize-avatars.md) - Avatar optimization guide
- [Wallet-Owned Assets Approach](docs/WALLET_OWNED_ASSETS_AVATAR_APPROACH.md) - Configure avatars from connected wallet (RMRK EVM, Thirdweb)
- [Model Format Specification](docs/model-format-specification.md) - Format compatibility between applications
- [Modder Documentation](docs/docs/Modders/getting-started.md) - Guide for custom assets and manifests (base body = layer 0, soulbound)
- [Code Map](docs/CODE_MAP.md) - module groups and where the source lives
- [History & Roadmap](docs/docs/history.md) - Project history and roadmap (wallet load profiles, mint files, AI personality)
