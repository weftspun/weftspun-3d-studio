# CUDA tests need the NVIDIA runtime libraries (nccl, cublas, cudart,
# cudnn, nvshmem) and XLA_TARGET=cuda12. Run them with:
#     mix test --include cuda

# RFD 0019 selects EXLA. XLA publishes no Windows archive, thus a
# checkout outside the dev container builds without it and starts on
# the Nx binary backend. RFD 0056 records the container.
#
# compute_test.exs holds both paths, thus exactly one applies on any
# host. Exclude the one that does not, in whichever direction that is.
backend_tag = if WeftspunStudio.Compute.available?(), do: false, else: true
ExUnit.configure(exclude: [:cuda, {:exla, backend_tag}])

# Database tests need the local CockroachDB cluster. Start it with:
#     cockroach start-single-node --insecure --store=.crdb/data \
#       --listen-addr=127.0.0.1:26257
Ecto.Adapters.SQL.Sandbox.mode(WeftspunStudio.Repo, :manual)

ExUnit.start()
