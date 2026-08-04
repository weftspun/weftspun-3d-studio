import Config

# `popcorn.cook` writes the AtomVM bundle here. The JavaScript build
# reads it from the same folder, and the webview loads it from there.
#
# No `start_module`. That option wants a module with `start/0`, and
# the boot code starts this project as an OTP application, which
# `mix.exs` names with `mod: {WeftspunPopcorn.Application, []}`.
config :popcorn, out_dir: "dist/wasm"
