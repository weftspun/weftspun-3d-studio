# RFD 0055: BEAM workers, local first

**State:** discussion
**Scope:** `weftspun_studio/`, every model image

## Problem

Replicate runs each model as a serverless Cog. That model costs more
than it should, and it fights the stack in three ways.

**Cog is Python, and this is an Elixir shop.** Replicate runs a
`predict.py`, thus no Elixir queue, no supervision tree, and no Nx
work can live inside the worker.

**The price is a markup, and the retention terms are Replicate's,
not ours.** Replicate bills per second above the cost of the card,
volume and long jobs make that worse, and a job's data lives as long
as Replicate's own terms say, not RFD 0058's zero-trust design.

**The boundary leaked into the repository.** It produced a duplicate
application in `cms/`, and a passthrough whose model map was empty,
thus every job answered 400.

## Decision

Blocklist Replicate. Run the worker on this box's own 4090 first, in
plain Docker images, on RFD 0058's existing Quadlets. vast.ai stays
priced and ready, the next tier once this box stops being enough, per
RFD 0062's Gall's law, not the immediate plan.

The BEAM owns the queue, the retries, and the state, no Python
involved, whichever host runs it.

See `DETAILS.md` for the providers priced for later, the host tiers,
the two phases, and what stays unresolved.

## Related

RFD 0036 gives the image convention. RFD 0027 gives the GPU tier.
RFD 0040 records the first worker. RFD 0019 records the core.
