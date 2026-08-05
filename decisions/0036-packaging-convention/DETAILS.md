# RFD 0036 details: the target, the rules, stages, files, composites, status

## The target

An RTX 4090 with 24 GB, at about 0.35 to 0.37 US dollars per hour on
demand, and 0.13 interruptible.

RFD 0027 records that every model in the catalog reaches a 24 GB card.
That is what makes one card type enough.

## The rules

- One model per image. An image that holds two cannot scale one
  without the other.
- Load the weights at start, and not per request. An instance is
  rented by the hour, thus a load per request buys nothing and costs
  every response.
- Serve `/health` and `/predict`. vast.ai runs no health probe of its
  own, thus a caller polls `/health` until the instance is ready.
- Download the weights at build time. A cold start that pulls 24 GB is
  a cold start that times out.
- Pin every version, and pin the upstream commit. A moved tag changes
  the output with no build change to show for it.
- Return 400 for a bad request, and not 500. A 500 sends a caller to
  retry a request that can never work.
- Return a USD layer beside the transmission file. RFD 0053 gives that
  rule.
- Name the license. RFD 0028 gates what ships.

## Two stages in one Dockerfile

The `contract` stage carries the server and `usd-core`, and no model.
It builds in seconds on any machine, and `WEFTSPUN_STUB=1` makes
`/predict` answer with the real shape and no GPU.

The `worker` stage is the real image. It carries CUDA, the upstream
source, and the weights.

That split is what makes the contract testable. RFD 0040 records a run
of it in Docker on a machine with no NVIDIA device.

## Files in each folder

| File            | Holds                                        |
| --------------- | -------------------------------------------- |
| README.md       | The RFD. Why this model, and what it costs.  |
| Dockerfile      | Both stages, the CUDA version, the weights.  |
| server.py       | `/health`, `/predict`, and the type schema.  |
| test_input.json | One request body, for the contract stage.    |
| domain.ex       | A composite model only. See RFD 0037.        |
| problem.ex      | A composite model only. See RFD 0037.        |
| plan.ex         | The solved plan. The planner writes it.      |

## What a composite model does

Five models in the catalog run more than one network. RFD 0037 models
each one as a taskweft domain, and not as a Python script. The server
then calls the plan, and each step is one action.

## The other folders are not converted yet

RFD 0040 is the worked example. It carries a `Dockerfile`, a
`server.py`, and a `test_input.json`, and RFD 0040 records a run of
the contract stage in Docker.

Fourteen model folders still carry a `cog.yaml` and a `predict.py`.
This folder carries a fifteenth `cog.yaml`, the template the other
fourteen copied. They describe the same models, and they name a
package format this RFD no longer selects.

The folder names no longer carry that format. Each folder is now
named for its model alone.

Convert one when the model is next worked on, and not in a sweep. A
folder converted without a build produces a `server.py` that nobody
ran, which is what the Cog files already are.
