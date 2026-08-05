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
of the card, and volume and long jobs both make that worse.

**The boundary leaked into the repository.** It produced a duplicate
application in `cms/`, and a passthrough whose model map was empty,
thus every job answered 400.

## Decision

Run the workers on vast.ai, in plain Docker images.

vast.ai is a peer-to-peer marketplace built around Docker. It rents an
instance, runs a container, and maps the GPU. Nothing about that
shape is Python. The BEAM then owns the queue, the retries, and the
state, across distributed nodes, which is what Replicate held before.

See `DETAILS.md` for the providers this RFD compared, the two host
tiers, the two phases, the one-image question, and what stays
unresolved.

## Related

RFD 0036 gives the image convention. RFD 0027 gives the GPU tier.
RFD 0040 records the first worker. RFD 0019 records the core.
