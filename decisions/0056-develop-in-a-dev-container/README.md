# RFD 0056: Develop in a dev container

**State:** discussion
**Scope:** `.devcontainer/`

## Problem

Two dependencies do not build on Windows, and both are required. XLA
publishes no Windows archive, so EXLA can never resolve there. The
V-Sekai CockroachDB release does ship a Windows zip, and the
database tests need a running node either way.

Work on Windows therefore either skips those parts or replaces them.
This branch already did both, and neither workaround is the answer.
See `DETAILS.md` for why.

## Decision

Develop in a dev container. It runs Debian, thus EXLA builds and the
Linux CockroachDB build runs.

vast.ai runs Linux as well, and RFD 0055 selects it, so the container
is the same system production uses. Torchx goes: EXLA is the only
backend this project builds against, and a second one only existed
to work around the host.

VSCodium carries no Dev Containers support. The Microsoft extension
is proprietary, and Open VSX does not carry it. Enter the container
by CLI instead, through `podman exec` or the `devcontainer` CLI, and
not through editor integration. The editor still edits the source
through the bind mount this RFD already sets.

See `DETAILS.md` for what the container carries, why it uses named
volumes instead of bind mounts, and what it deliberately does not do.

## Related

RFD 0019 selects EXLA. RFD 0020 selects the CockroachDB build.
RFD 0036 packages the model images. RFD 0055 selects vast.ai.
