# RFD 0019 details: shape, phases, compute, ports, packaging, risk, references

## The end shape

The end shape is an API server. The server holds the content and the
model data. It answers over HTTP. A headless content system works the
same way. The browser client becomes one consumer of that API. Other
consumers may follow, such as the XR client or a command line tool.

Grow an Elixir application beside the client, following the
strangler fig pattern. The new application takes one responsibility
at a time. The client keeps every other responsibility.

## Phases after phase 1

Phase 2 turns the direction around. The Elixir application becomes
the source. A build step writes the JavaScript catalog, and RFD 0016
needs an update at that point.

Later phases take the job lifecycle from RFD 0003, then the pipeline
graph from RFD 0002. A phase ends only after the parity check
passes. The old path stays until then.

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

## Ports and facts

The application follows the hexagonal shape from
`holographic-item-memory`. A `*_source` port reads inbound. A
`*_sink` port writes outbound. `state` is the adapter's opaque
handle.

Mox covers each port. The job ports reach the DGX backend and run
model work, so no test uses a real job adapter.

A catalog entry is a fact, not a fixed row. A license gate vetoes a
model. A benchmark moves a recommendation. RFD 0016 records that
churn. Each fact therefore carries a trust score and a timestamp,
after the hermes-agent holographic memory store. The field names
follow that store: `content`, `category`, and `tags`.

A veto lowers trust. It does not drop the fact. The veto is itself a
fact worth keeping, so a later reader learns why the model left.

The HRR vector from that store is not here yet. It needs Nx work. A
later phase adds it.

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
