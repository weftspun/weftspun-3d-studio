# RFD 0019: Strangler fig for the studio core

**State:** discussion
**Scope:** `weftspun_studio/`

## Problem

The browser client holds the studio logic. It holds the model
catalog, the job lifecycle, and the pipeline graph. A browser tab
owns state that outlives the tab. A page refresh drops that state.

The client calls the DGX API with no server between them. Each new
task type adds more client code.

A full rewrite carries risk. The client works today. A rewrite would
stop the work for a long time.

## Decision

The end shape is an API server. The server holds the content and the
model data. It answers over HTTP. A headless content system works the
same way. The browser client becomes one consumer of that API. Other
consumers may follow, such as the XR client or a command line tool.

Grow an Elixir application beside the client. Follow the strangler
fig pattern. The new application takes one responsibility at a time.
The client keeps every other responsibility.

The first responsibility is the model inventory from RFD 0016.

Phase 1 changes no behavior. The Elixir application holds the
inventory as data. It reads the JavaScript catalog. It reports each
difference. The JavaScript catalog stays authoritative, as RFD 0016
states.

Phase 2 turns the direction around. The Elixir application becomes
the source. A build step writes the JavaScript catalog. RFD 0016
needs an update at that point.

Later phases take the job lifecycle from RFD 0003. After that they
take the pipeline graph from RFD 0002.

A phase ends only after the parity check passes. The old path stays
until then.

## Compute

The application uses Nx for tensor work. The backend is EXLA. EXLA
compiles `Nx.Defn` graphs with Google XLA. It runs them on an NVIDIA
device through the CUDA client.

Build the dependency with `XLA_TARGET=cuda12`. The client follows the
build target. A CPU build registers only the host platform, so a
request for the CUDA client fails on the first tensor op.

An earlier draft selected nx-ggml, to match the ggml runtime in
see-through.cpp. EXLA replaces it. The DGX hardware is NVIDIA, so the
CUDA path uses the hardware the project already owns.

## Packaging

Burrito wraps the release into one binary. The target machine needs
no Elixir and no Erlang. The Burrito build step needs Zig.

The binary reads its arguments through `Burrito.Util.Args`. A
release must not read `System.argv/0`.

## Risk

A CUDA build of EXLA needs the NVIDIA runtime libraries on the host.
It needs nccl, cublas, cudart, cudnn, and nvshmem. The NIF fails to
load without them. The development machine lacks them today, so the
test suite runs on the host platform.

The test suite tags the CUDA tests. `mix test` excludes them. Run
`mix test --include cuda` on a machine with the runtime.

The inventory commands do not need the compute path.

Zig is absent on the current development machine. The release
assembles, but it produces no cross-compiled binary yet.

## References

- Inventory source: `decisions/0016-deep-learning-model-inventory.md`
- JavaScript catalog: `src/library/aiModelsCatalog.js`
- Elixir inventory: `weftspun_studio/lib/weftspun_studio/inventory.ex`
- Parity check: `weftspun_studio/lib/weftspun_studio/js_catalog.ex`
- Backend: https://github.com/elixir-nx/nx/tree/main/exla
- Burrito: https://github.com/burrito-elixir/burrito

## Related

RFD 0016 records the inventory that phase 1 mirrors. RFD 0006
records the See-Through stage. RFD 0003 and RFD 0002 name the later
phases.
