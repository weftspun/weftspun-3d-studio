# Weftspun 3D Studio

Weftspun 3D Studio is a 3D AIGC application with WebXR support. It
holds three parts in one application:

- the Open3DStudio generation tools
- WebXR, and WebGPU features
- VRM avatar authoring, with appearance traits, animation, and export

`apps/weftspun_studio/`, `apps/character_taxonomy/`, and
`apps/usd_viewer_app/` each deploy on their own. Every design
decision behind them, RFD 0000 onward, lives in
[weftspun/request-for-discussion](https://github.com/weftspun/request-for-discussion),
not in this repository.

## Acknowledgments

The project started as Open3DStudio. It then took the name Weftspun
3D Studio and added WebXR and WebGPU.

The avatar and VRM workflows now run in the same application. An
earlier version held them apart, under the name Character Studio.

The application extends
[Minimal3DStudio](https://github.com/FishWoWater/Minimal3DStudio). It
does work similar to
[TripoStudio](https://studio.tripo3d.ai/home?lng=en).

- [Three.js](https://threejs.org/) for 3D rendering
- [@pixiv/three-vrm](https://github.com/pixiv/three-vrm) for VRM model support
- [3DAIGC-API](https://github.com/AlfaOmegaGrafx/3DAIGC-API) for the backend API
- [TripoStudio](https://studio.tripo3d.ai/) for inspiration
- [Minimal3DStudio](https://github.com/FishWoWater/Minimal3DStudio) for the foundation
- [Atlas Foundation](https://github.com/AtlasFoundation/AvatarCreator) (MIT). The first open-source avatar creator in this lineage.
- [Webaverse](https://github.com/webaverse-studios/CharacterCreator) (MIT). Carried that avatar creator forward, as Character Creator.
- [M3-org](https://github.com/M3-org) for the upstream avatar-trait foundation
- [Character Studio](https://github.com/M3-org/CharacterStudio) (M3-org, MIT). The upstream avatar toolkit this project grew from.
- [OpenNexus3DStudio](https://github.com/AlfaOmegaGrafx/OpenNexus3DStudio): SPACE-TIME EDITION (MIT). The upstream project of this fork.
