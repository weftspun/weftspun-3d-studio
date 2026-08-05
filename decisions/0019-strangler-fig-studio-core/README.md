# RFD 0019: Strangler fig for the studio core

**State:** discussion
**Scope:** `weftspun_studio/`

## Problem

The browser client holds the studio logic: the model catalog, the
job lifecycle, and the pipeline graph. A browser tab owns state that
outlives the tab, and a page refresh drops that state. The client
calls the DGX API with no server between them, and each new task
type adds more client code.

A full rewrite carries risk. The client works today, and a rewrite
would stop the work for a long time.

## Decision

Grow an Elixir application beside the client, an API server the
browser client becomes one consumer of. RFD 0016's model inventory
is the first responsibility it takes. Phase 1 changes no behavior:
the Elixir application holds the inventory as data, reads the
JavaScript catalog, and reports each difference. The JavaScript
catalog stays authoritative, as RFD 0016 states.

See `DETAILS.md` for the end shape, the later phases, the compute
backend, the port shape, the packaging, and known risks.

## Related

RFD 0016 records the inventory that phase 1 mirrors. RFD 0006
records the See-Through stage, and RFD 0003 and RFD 0002 name the
later phases.
