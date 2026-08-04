# CUDA tests need the NVIDIA runtime libraries (nccl, cublas, cudart,
# cudnn, nvshmem) and XLA_TARGET=cuda12. Run them with:
#     mix test --include cuda
ExUnit.configure(exclude: [:cuda])

# Database tests need the local CockroachDB cluster. Start it with:
#     cockroach start-single-node --insecure --store=.crdb/data \
#       --listen-addr=127.0.0.1:26257
Ecto.Adapters.SQL.Sandbox.mode(WeftspunStudio.Repo, :manual)

ExUnit.start()
