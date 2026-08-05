# RFD 0054: The planner inside the studio core

**State:** discussion
**Scope:** `weftspun_studio/`

## Problem

`extension/` ran Elixir in an editor panel, through Popcorn and
AtomVM. It proved the pipeline, and it could not ship.

AtomVM needs `SharedArrayBuffer`, thus the page must be cross-origin
isolated. An editor webview is not isolated, and an extension cannot
set the headers. The panel worked only with `codium --enable-coi`.

The proof stands, and the vehicle does not.

## Decision

Delete `extension/`. Put the planner inside `weftspun_studio`, which
RFD 0019 already makes the API server.

RFD 0023 gives the shape, and this RFD does not restate it.

See `DETAILS.md` for the wrong-answer record of a second application
and the port-mocking rule. It also gives the measured plans, three
taskweft fixes this work needed, and the two planner routes.

## Related

RFD 0019 makes this the API server. RFD 0023 gives the shape. RFD 0037
gives the composite convention. RFD 0055 selects the worker host.
