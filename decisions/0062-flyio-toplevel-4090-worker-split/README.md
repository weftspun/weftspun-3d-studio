# RFD 0062: A Fly.io toplevel, and the 4090 as a worker node

**State:** discussion
**Scope:** `weftspun_studio/`, `deploy/quadlet/`, the deploy target

## Problem

RFD 0058 puts the whole stack — router, planner, catalog,
CockroachDB — on one box, with every port bound to `127.0.0.1`. That
is correct for a single operator on that box. It is not a product.
Nobody but the person sitting at this machine can reach it.

RFD 0055 answers a different question: where does the GPU work run.
It prices three rented options and picks vast.ai, at about $0.35/hr
for a verified RTX 4090. This project already owns one. RFD 0027
already sized every model in the catalog at a 24 GB tier — the exact
size of the card sitting in this box. Renting the same tier this box
already has is a cost with no matching benefit, for a single-operator
deployment.

Two problems, one shape: this box should keep doing GPU work, and
something else needs to be the thing a user reaches.

## Decision

Split the deployment by role, not by RFD 0058's single-box shape.

| Node | Runs | Reachable by |
| --- | --- | --- |
| **Toplevel** (Fly.io) | `weftspun_studio` (router, planner, catalog), CockroachDB, the built browser client | the public internet |
| **Worker** (this 4090 box, localhost) | the model Cogs, dispatched jobs | the toplevel node only, over Tailscale |

The worker keeps RFD 0058's quadlets exactly as written —
`weftspun.network`, loopback-only `PublishPort`, the same zero-trust
shape. What moves off this box is the *toplevel* role: the router,
the planner, and CockroachDB relocate to Fly.io, where a public IP
and a public product actually make sense.

taskweft's own MCP server already runs this way —
`https://taskweft-mcp.fly.dev/mcp`, cited in RFD 0037. Fly.io is not
a new tool for this project's dependency graph.

## Why Fly for the toplevel, and not the worker

Fly.io machines with a GPU are priced for rented GPU time, the same
market RFD 0055 already priced vast.ai against. Nothing changes that
comparison by moving the GPU there — it would cost more than the GPU
this project already has power drawn for, sitting in this box.

The router, the planner, and CockroachDB need none of that. RFD 0027
never sized them — they are not a model, and they hold no weights.
A small, cheap, always-on Fly machine is the right size for them,
and it is the piece that benefits from a public IP: a router with no
public address routes nothing.

## Why the worker stays on Tailscale, not a public port

RFD 0058 grounds its whole design in one fact: a bound port past
`127.0.0.1` is a port the internet can reach. That fact does not
change because the caller moved to Fly instead of staying on this
box — it gets stronger, because now the caller really is off-box.

This box already runs Tailscale — RFD 0058's own firewall
investigation found `tailscale0` and a live `ts-forward` nftables
chain while chasing an unrelated Podman networking fault. Join the
Fly toplevel to the same tailnet, and bind the worker's job-receiving
port to the Tailscale interface's address, not `0.0.0.0` and not
only `127.0.0.1`. That is a third bind mode past the two RFD 0058
already uses: reachable by tailnet peers, and by nothing else —
still no public bind, still the same zero-trust framing, extended
across a WAN instead of confined to loopback.

## The port this project already built for exactly this

RFD 0023 designed `Ports.JobSink` / `Ports.JobSource` so the router
never learns which host runs a model:

> A vast.ai adapter implements the same two behaviors, thus the
> router never learns which host runs the model.

`WeftspunStudio.Adapters.ReplicateJobs` is the only adapter today,
and its own moduledoc calls itself "a passthrough, and nothing
more" — it forwards to Replicate's queue and translates Replicate's
six statuses into RFD 0003's four. A worker adapter for this box
does the same shape of translation, against a queue this project
runs itself instead of Replicate's.

This RFD names the target and does not build it. The adapter, its
wire format to the worker, and the worker-side receiver are open
work — see RFD 0057.

## What ships where

**Toplevel, on Fly.io:**
- `Dockerfile` at the repo root (RFD 0060 moved it there; RFD 0058
  already proved it builds a working release image) and a `fly.toml`
  this RFD does not yet write.
- CockroachDB, co-located with the router the same way RFD 0058 puts
  it beside `weftspun_studio` today — on a Fly Volume, since a Fly
  machine's own disk is ephemeral across restarts.
- The built browser client (`thirdparty/3d_studio/`), served the way
  RFD 0019 already intends: the router as the one thing a browser
  talks to.

**Worker, staying local:**
- `weftspun.network`, and the quadlet isolation pattern RFD 0058
  wrote — but not `weftspun-crdb.build`/`.container`/`.volume`
  themselves. CockroachDB is the toplevel's persistence, not the
  worker's; those three quadlets move with the router role, to
  wherever the toplevel's CockroachDB actually runs. The worker's
  role narrows to the model Cogs and their isolation, once the
  database they used to sit beside is gone from this box.
- A new job-receiving quadlet, not yet written, bound to the
  Tailscale interface per the section above.

## Gall's law, once more

RFD 0055 already invokes this: rent a card only after the owned one
is the bottleneck. This RFD is that step taken literally — the 4090
this box already has is the whole compute budget until it is not
enough, and renting on vast.ai stays exactly where RFD 0055 leaves
it, as the next tier once one box stops being enough.

## What this RFD does not do

It does not write `fly.toml`. It does not write the worker-side
job-receiving adapter or its wire format. It does not configure this
box's Tailscale ACLs to admit a Fly machine, or confirm Fly's side of
that join actually works — that pairing is asserted here, not run.
It does not move CockroachDB, which still runs where RFD 0058 put it
until the toplevel migration actually happens. RFD 0057 tracks all
four as open work.

It does not retire `ReplicateJobs`. RFD 0055 already records why that
adapter stays until a worker answers — this RFD gives that worker a
second candidate host, not a reason to remove the first.

## Related

RFD 0019 makes `weftspun_studio` the API server this RFD relocates.
RFD 0020 and RFD 0058 give the CockroachDB this RFD moves with it.
RFD 0023 gives the `JobSink`/`JobSource` ports this RFD's worker
adapter will implement. RFD 0027 sizes every model at the 24 GB tier
this box already has. RFD 0055 prices the rented alternative and
keeps `ReplicateJobs` alive until a worker answers. RFD 0057 tracks
the open items this RFD did not close.
