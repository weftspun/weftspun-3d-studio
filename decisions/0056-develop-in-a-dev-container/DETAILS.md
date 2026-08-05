# RFD 0056 details: what the container carries, volumes, what it does not do

## What the container carries

| Part          | Why                                          |
| ------------- | ----------------------------------------------|
| Elixir 1.17.3 | On Erlang 27, on Debian bookworm.            |
| cmake and g++ | EXLA compiles a NIF.                         |
| python3       | The model image check runs it.               |
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
