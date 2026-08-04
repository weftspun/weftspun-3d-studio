# Weftspun 3D Studio

[![MIT License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Cross-Platform](https://img.shields.io/badge/platform-MacOS%20%7C%20Windows%20%7C%20Web%20%7C%20XR-blue)](#)

Weftspun 3D Studio is a 3D AIGC application with WebXR support. It
holds three parts in one application:

- the Open3DStudio generation tools
- WebXR, WebGPU, and blockchain features
- VRM avatar authoring, with appearance traits, animation, and export

The [3DAIGC-API](https://github.com/AlfaOmegaGrafx/3DAIGC-API) serves
the models. That API runs on your own machine, so the workflows stay
local and cost nothing.

The application extends
[Minimal3DStudio](https://github.com/FishWoWater/Minimal3DStudio). It
does work similar to
[TripoStudio](https://studio.tripo3d.ai/home?lng=en).

## History

The project started as Open3DStudio. It then took the name Weftspun
3D Studio and added WebXR, WebGPU, and blockchain features.

The avatar and VRM workflows now run in the same application. An
earlier version held them apart, under the name Character Studio.

## Workflows

The application supports these workflows:

- text to 3D, and image to 3D
- mesh painting, segmentation, and retopology
- UV unwrapping
- VoxHammer mesh editing
- auto-rigging
- Gaussian splats, and explorable worlds
- avatar from image
- spatial-fabric publish, through RP1 and OMB
- VRM optimization, trait customization, and animation

## Goals

The [roadmap](decisions/docs/history.md#roadmap) lists two more
goals. A wallet connection loads a profile or mints a file. AI
personality features follow that.

An avatar takes a soulbound base body, as a VRM that no one can
transfer. Wearables and traits attach to that body, and an owner can
equip or remove them.

Work continues on avatar configuration from wallet assets. See
[Create an Avatar](decisions/docs/General/create-an-avatar.md#configure-programmatically)
and
[Wallet-Owned Assets Approach](decisions/docs/WALLET_OWNED_ASSETS_AVATAR_APPROACH.md).

## Acknowledgments

- [Three.js](https://threejs.org/) for 3D rendering
- [@pixiv/three-vrm](https://github.com/pixiv/three-vrm) for VRM model support
- [3DAIGC-API](https://github.com/AlfaOmegaGrafx/3DAIGC-API) for the backend API
- [TripoStudio](https://studio.tripo3d.ai/) for inspiration
- [Minimal3DStudio](https://github.com/FishWoWater/Minimal3DStudio) for the foundation
- [Atlas Foundation](https://github.com/AtlasFoundation/AvatarCreator) (MIT). The first open-source avatar creator in this lineage.
- [Webaverse](https://github.com/webaverse-studios/CharacterCreator) (MIT). Carried that avatar creator forward, as Character Creator.
- [M3-org](https://github.com/M3-org) for the upstream avatar-trait foundation
- [Character Studio](https://github.com/M3-org/CharacterStudio) (M3-org, MIT). The upstream avatar toolkit this project grew from.
- OpenNexus3DStudio: SPACE-TIME EDITION (MIT). The upstream project of this fork. Weftspun rebranded in full, as the trademark terms require.
