# CUDA tests need the NVIDIA runtime libraries (nccl, cublas, cudart,
# cudnn, nvshmem) and XLA_TARGET=cuda12. Run them with:
#     mix test --include cuda
ExUnit.configure(exclude: [:cuda])

# EXLA is a backend for Nx, and not a requirement of it. mix.exs skips
# the dependency where XLA publishes no archive, and Windows is such a
# host. The tests that need the backend carry `@describetag exla: true`
# and skip when it is absent, thus a run on that host reports a skip
# and not a failure.
unless WeftspunStudio.Compute.available?() do
  ExUnit.configure(exclude: [:cuda, {:exla, true}])
end

# Database tests need the local CockroachDB cluster. Start it with:
#     cockroach start-single-node --insecure --store=.crdb/data \
#       --listen-addr=127.0.0.1:26257
Ecto.Adapters.SQL.Sandbox.mode(WeftspunStudio.Repo, :manual)

ExUnit.start()
