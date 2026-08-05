# RFD Index

This directory holds Request-for-Discussion documents. It follows the
Oxide RFD style.

Each RFD is a reference design. It records a decision and points to
the canonical documentation. It does not restate the documentation.
See the STE policy below for the writing rules.

## Index

| RFD | Reference design | State |
|-----|------------------|-------|
| 0000 | Conventions (RFD style, STE, DRY) | published |
| 0001 | App shell and routing | published |
| 0002 | Studio pipeline graph | published |
| 0003 | Task Manager job lifecycle | published |
| 0004 | AIGC task catalog | published |
| 0005 | Avatar and VRM pipeline | published |
| 0006 | Layer decomposition (See-Through) | discussion |
| 0007 | Motion validation (Kimodo) | discussion |
| 0008 | Appearance trait extraction and remix | discussion |
| 0009 | Viewport and scene rendering | published |
| 0010 | WebXR and IWSDK lab | published |
| 0011 | Spatial fabric publish | published |
| 0012 | Wallet, minting, and x402 | abandoned |
| 0013 | Public demo deploy | published |
| 0014 | Batch processing | published |
| 0015 | Phygital passport | abandoned |
| 0016 | Deep learning model inventory | published |
| 0017 | Fork rebrand to Weftspun | published |
| 0018 | M3 documentation removal | discussion |
| 0019 | Strangler fig studio core | published |
| 0020 | CockroachDB persistence | published |
| 0021 | Shared HRR library | published |
| 0022 | Hexagonal client | published |
| 0023 | Ports and adapters with headless CMS style | published |
| 0024 | Nx and ggml | ideation |
| 0025 | Model memory arithmetic | published |
| 0026 | bf16 memory per model | published |
| 0027 | GPU residency budget | published |
| 0028 | Model license gate | published |
| 0029 | FOSS model replacements | published |
| 0030 | See-Through component models | published |
| 0031 | Geometry refinement and alpha wrap | discussion |
| 0032 | Alpha wrap rebuild on Geogram | ideation |
| 0033 | Geometric algorithms in the catalog | published |
| 0034 | Krea memory cross-check | published |
| 0035 | Legacy model identifiers | published |
| 0036 | Model packaging convention | discussion |
| 0037 | Composite models as taskweft domains | discussion |
| 0038 | Cog for trellis2_image_to_textured_mesh | discussion |
| 0039 | Cog for trellis2_image_mesh_painting | discussion |
| 0040 | Image for pixal3d_image_to_textured_mesh | discussion |
| 0041 | Cog for p3sam_mesh_segmentation | discussion |
| 0042 | Cog for krea2_turbo_text_to_image | discussion |
| 0043 | Cog for qwen_q4_k_m_image_edit | discussion |
| 0044 | Cog for seethrough_layer_decomposition | discussion |
| 0045 | Cog for kimodo_text_to_motion | discussion |
| 0046 | Cog for skintokens_auto_rig | discussion |
| 0047 | Cog for voxhammer_text_mesh_editing | discussion |
| 0048 | Cog for voxhammer_image_mesh_editing | discussion |
| 0049 | Cog for weftspun_image_to_world | discussion |
| 0050 | Cog for lingbot_map_environment_scan | prediscussion |
| 0051 | Cog for worldmirror2_reconstruct | discussion |
| 0052 | Cog for triposplat_image_to_splat | discussion |
| 0053 | OpenUSD as the internal format | discussion |
| 0054 | The planner inside the studio core | discussion |
| 0055 | BEAM workers on vast.ai | discussion |
| 0056 | Develop in a dev container | discussion |
| 0057 | Open work | published |
| 0058 | Zero trust networking | discussion |
| 0059 | Continuous integration, in one step | discussion |
| 0060 | A thirdparty/ reset | discussion |

## DRY policy

The repository keeps one source of truth for each design.

- The README describes the feature surface.
- The docs/ tree holds the detailed designs and roadmaps.
- The src/ tree implements the behavior.
- This directory records the durable decisions only.

An RFD points to the source. It does not copy the source.
An RFD that restates a document will drift. It must instead link the
document. When a design changes, update the source first. Then update
the RFD to point at the new source.

## STE policy

Each RFD uses ASD-STE100 Simplified Technical English. The rules:

- One sentence per instruction.
- Keep sentences under 25 words.
- Use active voice.
- Do not use marketing adjectives.
- Do not use phrasal verbs.
- Do not use semicolons or em dashes in prose.
- Name one thing by one name.

The repository enforces this with a linter:

```bash
npm run lint:ste
```

The linter fails when any file scores above 2.5 violations per 100
words. Add the npm script to CI before merge.
