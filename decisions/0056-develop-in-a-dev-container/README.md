# RFD 0056: Develop in a dev container

**State:** discussion
**Scope:** `.devcontainer/`

## Problem

Two dependencies do not build on Windows, and both are required.

XLA publishes no Windows archive. Nine of its nine release assets are
for other systems, thus EXLA can never resolve there.

The V-Sekai CockroachDB release does ship a Windows zip, and the
database tests need a running node either way.

Work on Windows therefore either skips those parts or replaces them.
This branch already did both. It swapped EXLA for Torchx, and it made
the dependency conditional on the platform.

Neither workaround is the answer. RFD 0019 selects EXLA because it
compiles `Nx.Defn` graphs, and Torchx runs them one operation at a
time.

## Decision

Develop in a dev container. It runs Debian, thus EXLA builds and the
Linux CockroachDB build runs.

vast.ai runs Linux as well. RFD 0055 selects it, thus the container is
the same system production uses.

Torchx goes. EXLA is the only backend this project builds against, and
a second one only existed to work around the host.

## What the container carries

| Part          | Why                                          |
| ------------- | -------------------------------------------- |
| Elixir 1.17.3 | On Erlang 27, on Debian bookworm.            |
| cmake and g++ | EXLA compiles a NIF.                         |
| python3       | The STE linter and the model image check.    |
| Docker in Docker | The model images build here.              |
| CockroachDB   | `mix weftspun.crdb install` fetches it.      |

Debian, and not Alpine. The XLA archive links against shared libraries
that a musl base does not carry.

## Two volumes, and not bind mounts

`_build` and `deps` each take a named volume. A bind mount from a
Windows host makes both slow, because the BEAM writes many small files
into them.

The source stays a bind mount. An edit on the host must reach the
container without a copy.

## What this does not do

It does not give the container a GPU. EXLA takes its host client here,
and `XLA_TARGET=cuda12` needs the NVIDIA runtime on the host.

RFD 0027 records that every model reaches a 24 GB card. That card is
rented, and it is not this machine.

## Related

RFD 0019 selects EXLA. RFD 0020 selects the CockroachDB build.
RFD 0036 packages the model images. RFD 0055 selects vast.ai.
