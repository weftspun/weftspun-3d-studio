# CUDA tests need a CUDA build of LibTorch. Fetch it with
# LIBTORCH_TARGET=cu124, then run them with:
#     mix test --include cuda

# Torchx binds LibTorch, which ships for every host this project runs
# on. A build where LibTorch did not fetch still starts, on the Nx
# binary backend.
#
# compute_test.exs holds both paths, thus exactly one of them applies
# on any host. Exclude the one that does not, in whichever direction
# that is. Excluding only one direction would fail the other set.
backend_tag = if WeftspunStudio.Compute.available?(), do: false, else: true
ExUnit.configure(exclude: [:cuda, {:torchx, backend_tag}])

# Database tests need the local CockroachDB cluster. Start it with:
#     cockroach start-single-node --insecure --store=.crdb/data \
#       --listen-addr=127.0.0.1:26257
Ecto.Adapters.SQL.Sandbox.mode(WeftspunStudio.Repo, :manual)

ExUnit.start()
