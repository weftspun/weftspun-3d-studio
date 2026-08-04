# Weftspun 3D Studio

[![MIT License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Cross-Platform](https://img.shields.io/badge/platform-MacOS%20%7C%20Windows%20%7C%20Web%20%7C%20XR-blue)](#)

**Weftspun 3D Studio** is a unified 3D AIGC application with advanced WebXR support. It combines legacy **Open3DStudio** capabilities with **Weftspun3DStudio** (WebXR, WebGPU, blockchain) and integrated **VRM avatar authoring** (appearance traits, animation, mint/export). It works closely with the [3DAIGC-API](https://github.com/AlfaOmegaGrafx/3DAIGC-API) to provide **completely locally deployed** and **free** 3DAIGC workflows. Basically it's an advanced version of the **[Minimal3DStudio](https://github.com/FishWoWater/Minimal3DStudio)** and much like a **replicate of [TripoStudio](https://studio.tripo3d.ai/home?lng=en)**.

**Project Evolution**: The project started as **Open3DStudio**, evolved into **Weftspun 3D Studio** with WebXR, WebGPU, and blockchain features, and now ships avatar/VRM workflows in the same app (formerly referred to separately as "Character Studio").

**Goals & structure**: The [roadmap](docs/docs/history.md#roadmap) includes connecting wallet to load profiles or mint files and AI personality features. Weftspun3DStudio uses a **soulbound base body** VRM (non-transferable) and **equippable** wearables/traits; programmatic avatar configuration from owned wallet assets is in progress (see [Create an Avatar](docs/docs/General/create-an-avatar.md#configure-programmatically) and [Wallet-Owned Assets Approach](docs/WALLET_OWNED_ASSETS_AVATAR_APPROACH.md)). Technical and product roadmaps are detailed in the docs (e.g. [Technical Roadmap: RPM Migration](docs/TECHNICAL_ROADMAP_RPM_MIGRATION.md)).

The supported workflows include text-to-3D, image-to-3D, mesh painting, segmentation, retopology, UV unwrapping, VoxHammer editing, auto-rigging, Gaussian splats, explorable worlds, avatar-from-image, spatial-fabric publish (RP1/OMB), VRM optimization, trait customization, animation, and more.

## 📄 License

**Weftspun 3D Studio** is licensed under the [MIT License](LICENSE). The code maintains continuity with the original Open3DStudio project while evolving as a unified 3D AIGC + avatar platform.

## 🙏 Acknowledgments

- [Three.js](https://threejs.org/) for 3D rendering
- [@pixiv/three-vrm](https://github.com/pixiv/three-vrm) for VRM model support
- [3DAIGC-API](https://github.com/AlfaOmegaGrafx/3DAIGC-API) for the backend API
- [TripoStudio](https://studio.tripo3d.ai/) for inspiration
- [Minimal3DStudio](https://github.com/FishWoWater/Minimal3DStudio) for the foundation
- [Atlas Foundation](https://github.com/AtlasFoundation/AvatarCreator) (MIT) — the original open-source avatar creator this lineage began with
- [Webaverse](https://github.com/webaverse-studios/CharacterCreator) (MIT) — carried the avatar creator forward as Character Creator
- [M3-org](https://github.com/M3-org) for the upstream avatar-trait foundation and inspiration
- [Character Studio](https://github.com/M3-org/CharacterStudio) (M3-org, MIT) — upstream open-source avatar toolkit this project evolved from
- OpenNexus3DStudio: SPACE-TIME EDITION (MIT) — the upstream project this fork derives from; rebranded in full per its trademark terms
