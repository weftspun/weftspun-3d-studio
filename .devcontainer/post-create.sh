#!/usr/bin/env bash
# Prepares the container after it builds. RFD 0056 records the design.
#
# Every step here is one that fails on a Windows host: the XLA archive,
# the CockroachDB binary, and a container runtime for the model images.
set -euo pipefail

echo "==> python tools"
# prek runs the hooks. The STE linter and the model image check are
# both python, and PyYAML backs the second one.
pip3 install --quiet prek pyyaml

echo "==> elixir dependencies"
cd weftspun_studio

# EXLA downloads a precompiled XLA archive. XLA_TARGET picks the
# client, and cuda12 needs the NVIDIA runtime libraries on the host.
# This container has no GPU, thus the default host build is correct.
mix deps.get

echo "==> compiling, which builds the EXLA NIF"
mix compile

echo "==> cockroachdb"
# The V-Sekai 22.1 build that RFD 0020 selects. The mix task derives
# the target, and RFD 0055 records the fault that hid the Linux and
# Windows assets from it.
mix weftspun.crdb install

cd ..

echo "==> git hooks"
prek install || echo "prek install failed. The hooks still run with: prek run --all-files"

echo "==> podman"
# Rootless podman needs the socket for a docker-compatible client.
systemctl --user enable --now podman.socket 2>/dev/null \
  || echo "the podman socket did not start. quadlet units still work."

cat <<'MESSAGE'

Ready.

  cd weftspun_studio
  mix weftspun.crdb        # a node on 127.0.0.1:26257, in the foreground
  mix test                 # needs that node

  mix run -e 'IO.inspect(WeftspunStudio.Compute.info())'

A model image, with no GPU and no weights:

  cd decisions/0040-pixal3d-image-to-textured-mesh
  podman build --target contract -t weftspun/pixal3d:contract .
  podman run --rm -p 8000:8000 weftspun/pixal3d:contract

A quadlet unit, for a service that must survive a restart:

  cp unit.container ~/.config/containers/systemd/
  systemctl --user daemon-reload
  systemctl --user start unit

MESSAGE
