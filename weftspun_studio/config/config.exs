import Config

# RFD 0019 selects EXLA on CUDA. Build the dependency with
# XLA_TARGET=cuda12 to get the NVIDIA accelerated client. That build
# also needs the NVIDIA runtime libraries on the host.
config :nx,
  default_backend: EXLA.Backend,
  default_defn_options: [compiler: EXLA]

# The client follows the build target. A CPU build of XLA registers
# only the Host platform, so asking for :cuda there would crash on
# the first tensor op.
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
