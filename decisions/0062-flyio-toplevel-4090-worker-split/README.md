# RFD 0062: A Fly.io toplevel, and the 4090 as a worker node

**State:** discussion
**Scope:** `weftspun_studio/`, `deploy/quadlet/`, the deploy target

## Problem

RFD 0058 puts the whole stack on one box, with every port bound to
`127.0.0.1`. That is correct for one operator, and it is not a
product. Nobody but the person sitting at this machine can reach it.

RFD 0055 prices three rented GPU options and picks vast.ai. This
project already owns an RTX 4090, and RFD 0027 already sized every
catalog model at that same 24 GB tier. Renting the tier this box
already has is a cost with no matching benefit, for one operator.

Two problems, one shape: this box should keep doing GPU work, and
something else needs to be the thing a user reaches.

## Decision

Split the deployment by role, not by RFD 0058's single-box shape.
`weftspun_studio`, its planner, its catalog, and CockroachDB move to
Fly.io, reachable by the public internet. The model images stay on
this box, on RFD 0058's quadlets exactly as written, reachable by
the Fly toplevel alone, over Tailscale.

taskweft's own MCP server already runs on Fly.io, cited in RFD 0037,
so this is not a new tool for the project.

`DETAILS.md` gives the full split, the reasoning behind each side,
the existing port this reuses, what ships where, and what this RFD
leaves undone.

## Related

RFD 0019 makes `weftspun_studio` the API server this RFD relocates.
RFD 0023 gives the ports the worker adapter will implement. RFD 0061
names the same asset transport for a different gap, browser uploads.
RFD 0057 tracks what this RFD left open.
