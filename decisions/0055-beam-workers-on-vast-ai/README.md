# RFD 0055: BEAM workers on vast.ai

**State:** discussion
**Scope:** `weftspun_studio/`, every model image

## Problem

Replicate runs each model as a serverless Cog. That model costs more
than it should, and it fights the stack in three ways.

**Cog is Python, and this is an Elixir shop.** Replicate runs a
`predict.py`, thus no Elixir queue, no supervision tree, and no Nx
work can live inside the worker.

**The price is a markup.** Replicate bills per second above the cost
of the card. Volume and long jobs both make that worse.

**The boundary leaked into the repository.** It produced a duplicate
application in `cms/`, and a passthrough whose model map was empty,
thus every job answered 400.

## Decision

Run the workers on vast.ai, in plain Docker images.

vast.ai is a peer-to-peer marketplace built around Docker. It rents an
instance, runs a container, maps the GPU, and exposes a port. Nothing
about that shape is Python.

The BEAM then owns the queue, the retries, and the state, across
distributed nodes. That is what Replicate held before, and it is what
the BEAM is for.

## What was considered

| Provider  | Model      | RTX 4090 | Against it             |
| --------- | ---------- | -------: | ---------------------- |
| vast.ai   | P2P market |   ~$0.35 | Host quality varies    |
| RunPod    | Datacenter |    $0.69 | Twice the price        |
| Google    | TPU spot   |    $0.60 | Needs XLA, breaks CUDA |
| Replicate | Serverless |     high | Hostile to the BEAM    |

The TPU row also disagrees with RFD 0019 now. That RFD first selected
EXLA, which is XLA. Torchx replaced it, because XLA publishes no
Windows archive, and Torchx binds LibTorch and CUDA.

## Two host tiers

vast.ai sells community hosts and verified hosts.

Take community hosts for development, near the price floor of about
0.15 US dollars per hour. Take verified hosts for production, at the
median of about 0.35, and accept the price for the PCIe lanes, the
bandwidth, and the privacy terms.

## Phase 1: unify the repository

1. Commit the Torchx swap, the CockroachDB fixes, and the
   let-it-crash pass. Done in `e1a4767b`.
2. Delete `cms/`, and fold the planning documents, the `Planner` port,
   and `TaskweftPlanner` into `weftspun_studio`. Done in `c2d659f7`.
   That settles the overlap RFD 0023 and RFD 0054 carried.
3. Remove the Replicate passthrough and `ReplicateJobs`. Open.
4. Abandon the Cog build. Done. RFD 0036 selects plain Docker, and
   RFD 0040 records a contract stage tested in Docker.

## Phase 2: deploy the compute

1. Write a `Dockerfile` for `weftspun_studio` with Elixir and CUDA.
2. Rent a development instance, on an RTX 4090.
3. Measure the inference speed, and cluster the router with the
   worker.

## One image, or one per model

This RFD proposes a unified image that holds the application and the
weights. RFD 0036 keeps one model per image.

The two disagree, and the weights decide it. RFD 0026 sums the catalog
at 116.45 GB. One image that carried all of it would take an hour to
pull, and a change to one model would rebuild every other.

Keep one image per model. Put the BEAM inside each one, which is what
this RFD asks for, and let the router cluster with them.

## Unresolved

vast.ai bills for storage while an instance is paused. Either the host
keeps the weights, or the container pulls them from a bucket at start.

Pixal3D is 24.045 GB. A pull at start costs minutes on every boot, and
host storage costs money on every pause. Measure both before choosing.

## Related

RFD 0036 gives the image convention. RFD 0027 gives the GPU tier.
RFD 0040 records the first worker. RFD 0019 records the core.
