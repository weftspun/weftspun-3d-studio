# Weftspun 3D Studio

Weftspun 3D Studio is a 3D AIGC application with WebXR support. It
holds three parts in one application:

- the Open3DStudio generation tools
- WebXR, and WebGPU features
- VRM avatar authoring, with appearance traits, animation, and export

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

## Two parts, one repository

This repository holds two applications, and this root is the newer
one.

**`weftspun_studio`**, the Elixir application at this root, is the
API server RFD 0019's strangler fig is growing toward: an API server
in the headless content system style. The rest of this document
covers it.

**The browser client**, at `thirdparty/3d_studio/`, is the React and
Three.js application the section above describes. It holds the
Open3DStudio generation UI, the WebXR and WebGPU code, and the VRM
avatar tools. RFD 0060 moved it there — before that move, it held
this repository's root, and `weftspun_studio` sat inside it as a
subdirectory. See `thirdparty/3d_studio/README.md` for its own build
steps.

The two talk to each other today the way RFD 0019 describes: this
application reads the client's model catalog
(`thirdparty/3d_studio/src/library/aiModelsCatalog.js`) and checks
its own inventory against it, and changes no behavior yet. RFD 0016
tracks that catalog as the source of truth until a later phase turns
the direction around.

## weftspun_studio

Studio core. Phase 1 changes no behavior: this application holds the
model inventory from RFD 0016 and checks the client catalog against
it, without yet serving that catalog to the client in its place.

### Build

```bash
mix deps.get
mix compile
mix test                  # CUDA tests excluded
mix test --include cuda   # needs the NVIDIA runtime
```

This machine has no `g++`. Point the build at clang:

```bash
export CC=clang CXX=clang++
```

### Commands

```bash
mix run -e 'WeftspunStudio.CLI.main(["models", "list"])'
mix run -e 'WeftspunStudio.CLI.main(["models", "list", "--group", "component"])'
mix run -e 'WeftspunStudio.CLI.main(["models", "verify"])'
mix run -e 'WeftspunStudio.CLI.main(["compute", "info"])'
```

`models verify` compares this inventory against the client catalog.
It exits non-zero on a difference, so CI can hold the two in step.

### Accelerator

RFD 0019 selects EXLA on CUDA. Build for the NVIDIA client:

```bash
export XLA_TARGET=cuda12
mix deps.compile xla exla --force
```

That build links against the NVIDIA runtime libraries. The host needs
nccl, cublas, cudart, cudnn, and nvshmem. Without them the NIF fails
to load. A build with no `XLA_TARGET` runs on the host platform and
the suite stays green.

### Single binary

Burrito wraps the release into one binary. The step needs Zig.

```bash
MIX_ENV=prod mix release weftspun
```

A Burrito binary reads `Burrito.Util.Args.argv/0`. It does not
populate `System.argv/0`.

RFD 0058 also gives a Podman Quadlet deployment, the production path
on a single box:

```bash
sudo bash scripts/deploy-weftspun-quadlet.sh
```

## Decisions

`decisions/` holds this project's RFDs — the reference designs for
both applications, in the Oxide RFD style. Start at
`decisions/README.md`.
