# RFD 0056: Develop in a dev container

**State:** discussion
**Scope:** `.devcontainer/`

## Problem

Two dependencies do not build on Windows, and both are required.

XLA publishes no Windows archive. Nine of its nine release assets are
for other systems, thus EXLA can never resolve there. The V-Sekai
CockroachDB release does ship a Windows zip, and the database tests
need a running node either way.

Work on Windows therefore either skips those parts or replaces them.
This branch already did both. It swapped EXLA for Torchx, and it made
the dependency conditional on the platform.

Neither workaround is the answer. RFD 0019 selects EXLA because it
compiles `Nx.Defn` graphs, and Torchx runs them one operation at a
time.

## Decision

Develop in a dev container. It runs Debian, thus EXLA builds and the
Linux CockroachDB build runs.

vast.ai runs Linux as well, and RFD 0055 selects it, so the container
is the same system production uses. Torchx goes: EXLA is the only
backend this project builds against, and a second one only existed
to work around the host.

See `DETAILS.md` for what the container carries, why it uses named
volumes instead of bind mounts, and what it deliberately does not do.

## Related

RFD 0019 selects EXLA. RFD 0020 selects the CockroachDB build.
RFD 0036 packages the model images. RFD 0055 selects vast.ai.
