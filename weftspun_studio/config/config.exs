import Config

# Persistence. RFD 0020 selects the V-Sekai CockroachDB build. It
# speaks the PostgreSQL wire protocol, so the Postgres adapter drives
# it without change.
config :weftspun_studio, ecto_repos: [WeftspunStudio.Repo]

# RFD 0019 first selected EXLA. XLA publishes no Windows archive, thus
# Torchx replaces it. Torchx binds LibTorch, which ships for every host
# this project runs on. Build with LIBTORCH_TARGET=cu124 for CUDA.
#
# Nx falls back to its binary backend when Torchx is absent. Naming a
# backend that did not build would crash the first tensor op.
if Code.ensure_loaded?(Torchx) do
  config :nx, default_backend: Torchx.Backend
end

# Per environment settings follow. The database name and the pool
# differ between a developer machine and the test suite.
import_config "#{config_env()}.exs"
