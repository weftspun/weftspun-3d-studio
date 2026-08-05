# RFD 0062 details: why Fly, why Tailscale, the existing port, what ships, Gall's law, scope

## The split, node by node

| Node | Runs | Reachable by |
| --- | --- | --- |
| **Toplevel** (Fly.io) | `weftspun_studio` (router, planner, catalog), CockroachDB, the built browser client | the public internet |
| **Worker** (this 4090 box, localhost) | the model images, dispatched jobs | the toplevel node only, over Tailscale |

## Why Fly for the toplevel, and not the worker

Fly.io machines with a GPU are priced for rented GPU time, the same
market RFD 0055 already priced vast.ai against. Moving the GPU there
changes nothing in that comparison. It would cost more than the GPU
this project already has power drawn for, sitting in this box.

The router, the planner, and CockroachDB need none of that. RFD 0027
never sized them. They are not a model, and they hold no weights. A
small, cheap, always-on Fly machine is the right size for them, and
it is the piece that benefits from a public IP. A router with no
public address routes nothing.

## Why the worker stays on Tailscale, not a public port

RFD 0058 grounds its whole design in one fact. A bound port past
`127.0.0.1` is a port the internet can reach. That fact does not
change because the caller moved to Fly instead of staying on this
box. It gets stronger, because now the caller really is off-box.

This box already runs Tailscale. RFD 0058's own firewall
investigation found `tailscale0` and a live `ts-forward` nftables
chain while chasing an unrelated Podman networking fault. Join the
Fly toplevel to the same tailnet, and bind the worker's job-receiving
port to the Tailscale interface's address, not `0.0.0.0` and not
only `127.0.0.1`.

That is a third bind mode past the two RFD 0058 already uses. It is
reachable by tailnet peers, and by nothing else. It still holds no
public bind, and it still keeps the same zero-trust framing, now
extended across a WAN instead of confined to loopback.

## The port this project already built for exactly this

RFD 0023 designed `Ports.JobSink` / `Ports.JobSource` so the router
never learns which host runs a model:

> A vast.ai adapter implements the same two behaviors, thus the
> router never learns which host runs the model.

`WeftspunStudio.Adapters.ReplicateJobs` is the only adapter today.
Its own moduledoc calls itself "a passthrough, and nothing more." It
forwards to Replicate's queue and translates Replicate's six statuses
into RFD 0003's four. A worker adapter for this box does the same
shape of translation, against a queue this project runs itself
instead of Replicate's.

This RFD names the target and does not build it. The adapter, its
wire format to the worker, and the worker-side receiver are open
work. See RFD 0057.

## What ships where

**Toplevel, on Fly.io:**
- `Dockerfile` at the repo root (RFD 0060 moved it there, and RFD
  0058 already proved it builds a working release image) and a
  `fly.toml` this RFD does not yet write.
- CockroachDB, co-located with the router the same way RFD 0058 puts
  it beside `weftspun_studio` today, on a Fly Volume, since a Fly
  machine's own disk is ephemeral across restarts.
- The built browser client (`thirdparty/3d_studio/`), served the way
  RFD 0019 already intends: the router as the one thing a browser
  talks to.

**Worker, staying local:**
- `weftspun.network`, and the quadlet isolation pattern RFD 0058
  wrote. Not `weftspun-crdb.build`/`.container`/`.volume`
  themselves, though. CockroachDB is the toplevel's persistence, not
  the worker's, so those three quadlets move with the router role,
  to wherever the toplevel's CockroachDB actually runs. The worker's
  role narrows to the model images and their isolation, once the
  database they used to sit beside is gone from this box.
- A new job-receiving quadlet, not yet written, bound to the
  Tailscale interface per the section above.

## Gall's law, once more

RFD 0055 already invokes this: rent a card only after the owned one
is the bottleneck. This RFD takes that step literally. The 4090 this
box already has is the whole compute budget until it is not enough.
Renting on vast.ai stays exactly where RFD 0055 leaves it, as the
next tier once one box stops being enough.

## What this RFD does not do

It does not write `fly.toml`. It does not write the worker-side
job-receiving adapter or its wire format. It does not configure this
box's Tailscale ACLs to admit a Fly machine, or confirm Fly's side of
that join actually works. That pairing is asserted here, not run. It
does not move CockroachDB, which still runs where RFD 0058 put it
until the toplevel migration actually happens. RFD 0057 tracks all
four as open work.

It does not retire `ReplicateJobs`. RFD 0055 already records why that
adapter stays until a worker answers. This RFD gives that worker a
second candidate host, not a reason to remove the first.
