import Config

# Persistence. RFD 0020 selects the V-Sekai CockroachDB build. It
# speaks the PostgreSQL wire protocol, so the Postgres adapter drives
# it without change.
config :weftspun_studio, ecto_repos: [WeftspunStudio.Repo]

# RFD 0019 selects EXLA, and nothing else. EXLA compiles Nx.Defn
# graphs with XLA. Build it with XLA_TARGET=cuda12 for the NVIDIA
# client, which also needs the NVIDIA runtime libraries on the host.
#
# XLA publishes no Windows archive. Develop in the dev container,
# which runs Linux. RFD 0056 records it.
#
# A build without EXLA still starts, on the Nx binary backend. Naming a
# backend that did not build crashes the first tensor op.
if Code.ensure_loaded?(EXLA) do
  config :nx,
    default_backend: EXLA.Backend,
    default_defn_options: [compiler: EXLA]
end

# The EXLA client follows the build target. A CPU build of XLA
# registers only the Host platform, thus asking for :cuda there would
# crash on the first tensor op.
default_client =
  if System.get_env("XLA_TARGET", "") =~ ~r/^cuda/ do
    :cuda
  else
    :host
  end

config :exla,
  clients: [
    cuda: [platform: :cuda],
    host: [platform: :host]
  ],
  default_client:
    String.to_atom(System.get_env("WEFTSPUN_EXLA_CLIENT", to_string(default_client)))

# Per environment settings follow. The database name and the pool
# differ between a developer machine and the test suite.
import_config "#{config_env()}.exs"

# Which Replicate model runs each catalog id. RFD 0036 packages each
# one as its own Cog, and RFD 0040 measures the first.
#
# This map is the passthrough's whole vocabulary. An id that is absent
# answers 400 with the id named, thus a caller learns the gap instead
# of meeting a Replicate error in Replicate's own words.
#
# Every entry needs the version digest after the colon. A bare model
# name would follow whatever the owner pushes last, and RFD 0036
# requires a pin.
config :weftspun_studio,
  replicate_models: %{
    # RFD 0040. MIT, 12.02 B parameters, 24.045 GB of weights.
    "pixal3d_image_to_textured_mesh" => "weftspun/pixal3d",
    # RFD 0038. MIT. The backbone Pixal3D builds on.
    "trellis2_image_to_textured_mesh" => "weftspun/trellis2",
    # RFD 0039. Shares the RFD 0038 weights.
    "trellis2_image_mesh_painting" => "weftspun/trellis2-paint",
    # RFD 0041. MIT. Replaces PartField, which failed the RFD 0028 gate.
    "p3sam_mesh_segmentation" => "weftspun/p3sam",
    # RFD 0042.
    "krea2_turbo_text_to_image" => "weftspun/krea2-turbo",
    # RFD 0043. Apache 2.0, Q4_K_M only.
    "qwen_q4_k_m_image_edit" => "weftspun/qwen-image-edit",
    # RFD 0044. Apache 2.0. Nine networks behind one id.
    "seethrough_layer_decomposition" => "weftspun/seethrough",
    # RFD 0045.
    "kimodo_text_to_motion" => "weftspun/kimodo",
    # RFD 0046.
    "skintokens_auto_rig" => "weftspun/skintokens",
    # RFD 0051 and RFD 0052.
    "worldmirror2_reconstruct" => "weftspun/worldmirror2",
    "triposplat_image_to_splat" => "weftspun/triposplat"
  }
