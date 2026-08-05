# weftspun_studio

Studio core. The first root of the strangler fig in RFD 0019. RFD
0060 moved this application to the repo root, and moved the browser
client it once shared a root with to `thirdparty/3d_studio/`.

The end shape is an API server in the headless content system style.
The browser client becomes one consumer of that API.

Phase 1 changes no behavior. This application holds the model
inventory from RFD 0016 and checks the client catalog against it.
`thirdparty/3d_studio/src/library/aiModelsCatalog.js` stays
authoritative until phase 2.

## Build

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

## Commands

```bash
mix run -e 'WeftspunStudio.CLI.main(["models", "list"])'
mix run -e 'WeftspunStudio.CLI.main(["models", "list", "--group", "component"])'
mix run -e 'WeftspunStudio.CLI.main(["models", "verify"])'
mix run -e 'WeftspunStudio.CLI.main(["compute", "info"])'
```

`models verify` compares this inventory against the client catalog.
It exits non-zero on a difference, so CI can hold the two in step.

## Accelerator

RFD 0019 selects EXLA on CUDA. Build for the NVIDIA client:

```bash
export XLA_TARGET=cuda12
mix deps.compile xla exla --force
```

That build links against the NVIDIA runtime libraries. The host needs
nccl, cublas, cudart, cudnn, and nvshmem. Without them the NIF fails
to load. A build with no `XLA_TARGET` runs on the host platform and
the suite stays green.

## Single binary

Burrito wraps the release into one binary. The step needs Zig.

```bash
MIX_ENV=prod mix release weftspun
```

A Burrito binary reads `Burrito.Util.Args.argv/0`. It does not
populate `System.argv/0`.
