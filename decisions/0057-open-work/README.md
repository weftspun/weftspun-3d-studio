# RFD 0057: Open work

**State:** published
**Scope:** the repository

## Problem

This branch changed the host, the packaging, the backend, and the
planner. Some of that work is complete, some is measured but not
built, and some is written but never run.

A reader who returns to this cannot tell those apart from the RFDs
alone. Each RFD records its own decision, and none records what is
still owed.

## Decision

Keep one list of open work, here. Each entry names the RFD that owns
it, and what closing it needs.

Delete an entry when it closes. This RFD shrinks, and it never grows a
history section.

## Verified, and running

| What | Evidence |
| ---- | -------- |
| The planner composes three documents | `pipeline_test.exs`, 105 tests pass |
| The model image serves HTTP | RFD 0040, run in Docker on this machine |
| CockroachDB provisions and runs | RFD 0020, 92 tests with the node up |
| taskweft composition | PRs 207, 208, 209, merged upstream |
| Both Quadlets run end to end | RFD 0058, `weftspun.service` and `weftspun-crdb.service` both `active (running)`, `/api/v1/health` and `/api/v1/models` answered over `weftspun.network` |

## Written, and never run

**The dev container.** RFD 0056. The image does not build yet. The
Debian attempt failed at `mix local.hex`, and the Fedora rewrite
answers that by reading the error. Build it before trusting it.

**The Pixal3D worker stage.** RFD 0040. Only the contract stage ran.
The worker stage pulls 24.045 GB and needs an NVIDIA device, thus it
needs a rented card.

**The vast.ai host.** RFD 0055 Phase 2. No instance is rented, and no
worker answers.

## Measured, and not built

**Thirteen model folders.** RFD 0036. Each still carries a `cog.yaml`
and a `predict.py`, and RFD 0036 no longer selects Cog. Convert one
when its model is next worked on, and not in a sweep.

**`_to_usd` in the worker.** RFD 0053. The layer records the GLB as an
asset attribute, because `usd-core` alone reads no glTF. A glTF file
format plugin would let it be a reference arc.

## Unknown, and blocking a number

**`lingbot_map_environment_scan`.** RFD 0026 marks its parameter count
unknown, and it is the last such row. RFD 0050 stays in prediscussion
until it is measured.

**The Q4_K_M quality cost.** RFD 0043. Quantization is a price choice
now, and no measurement compares the two formats.

## Decided, and waiting on order

**The Replicate passthrough.** RFD 0055 Phase 1 step 3 removes it.
RFD 0055 also records why it stays until one vast.ai worker answers.

**Storage on vast.ai.** RFD 0055. Either the host keeps the weights,
or the container pulls them at start. Pixal3D is 24.045 GB, thus both
cost something. Measure before choosing.

## Related

RFD 0055 selects the host. RFD 0056 selects the development system.
RFD 0036 packages the models. RFD 0026 holds the memory numbers.
RFD 0058 gives the Quadlet deployment. RFD 0059 gives the one-step
build.
