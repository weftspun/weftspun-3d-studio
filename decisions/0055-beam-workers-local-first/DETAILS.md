# RFD 0055 details: the local worker, the rented tier priced for later, the two phases, image shape, unresolved

## What was considered, and when it applies

This project owns an RTX 4090, in this box. RFD 0062's Gall's law
applies here first: rent a card only after the owned one is the
bottleneck. The table below prices the rented tier, for the day this
box stops being enough, not for today.

| Provider  | Model      | RTX 4090 | Against it             |
| --------- | ---------- | -------: | ------------------------ |
| vast.ai   | P2P market |   ~$0.35 | Host quality varies    |
| RunPod    | Datacenter |    $0.69 | Twice the price        |
| Google    | TPU spot   |    $0.60 | Needs XLA, breaks CUDA |
| Replicate | Serverless |     high | Hostile to the BEAM, blocklisted |

The TPU row also disagrees with RFD 0019 now. That RFD first selected
EXLA, which is XLA. Torchx replaced it, because XLA publishes no
Windows archive, and Torchx binds LibTorch and CUDA.

## Two host tiers, for the rented future, not the local present

vast.ai sells community hosts and verified hosts, priced here for the
day this box needs a second card, not for the local worker this RFD
builds first.

Take community hosts for development, near the price floor of about
0.15 US dollars per hour. Take verified hosts for production, at the
median of about 0.35, and accept the price for the PCIe lanes, the
bandwidth, and the privacy terms.

## Phase 1: unify the repository

1. Commit the CockroachDB fixes and the let-it-crash pass. Done in
   `e1a4767b`. The Torchx swap in that commit is reverted, and
   RFD 0056 records why.
2. Delete `cms/`, and fold the planning documents, the `Planner` port,
   and `TaskweftPlanner` into `weftspun_studio`. Done in `c2d659f7`.
   That settles the overlap RFD 0023 and RFD 0054 carried.
3. Remove the Replicate passthrough and `ReplicateJobs`. Open, and see
   below.
4. Abandon the Cog build. Done in `06c5c4ba`. RFD 0036 selects plain
   Docker, and RFD 0040 records a contract stage tested in Docker.

## Replicate is blocklisted, and the passthrough is tolerated, not kept

Replicate is blocklisted on two grounds: the per-second markup, and
retention terms this project does not set and cannot audit. No new
dependency on Replicate is acceptable, matching the RFD 0028 gate's
own shape for a blocklisted model license.

Step 3 removes the only path from the router to a model. Nothing
replaces it yet, because Phase 2 has not run. `ReplicateJobs` keeps
running in code today, an explicit, temporary exception, not an
endorsement, until this box's own worker answers `/predict`. Then the
adapter changes host and keeps its port, which is what RFD 0023
makes possible.

`Ports.JobSink` and `Ports.JobSource` do not change. A local adapter
implements the same two behaviors, thus the router never learns which
host runs the model. A rented adapter, later, does the same.

## Phase 2: deploy the compute, on this box

1. Write a `Dockerfile` for `weftspun_studio` with Elixir and CUDA.
2. Run it on this box's own RTX 4090, through RFD 0058's Quadlets,
   already built and verified running. No instance to rent.
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

Local storage is not billed per pause, so the rented-tier question,
whether a host keeps the weights or a container pulls them from a
bucket at start, only reopens the day this box is not enough.

Pixal3D is 24.045 GB either way. Measure the local pull-at-start cost
before it matters for the rented tier too.
