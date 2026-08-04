# RFD 0036: Cog packaging convention

**State:** discussion
**Feature:** model packaging

## Problem

The DGX API runs each model through its own adapter. Each adapter
carries its own weight loader, its own CUDA pin, and its own output
writer. A new model needs a new adapter, and no adapter runs anywhere
else.

## Decision

Write one Replicate Cog per model. A Cog is a container with a
declared build and one `Predictor` class. It runs on Replicate, on the
DGX, and on a laptop, and the three give the same output.

Each model gets a folder under `decisions/`, and each folder holds
this RFD, a `cog.yaml`, and a `predict.py`.

## The rules

- One model per Cog. A Cog that holds two models cannot scale one
  without the other.
- `setup()` loads the weights. `predict()` must load nothing.
- `predict()` takes typed `Input` fields, and it returns `Path` or a
  `BaseModel`. It does not take a dict.
- Pin every weight by digest. A tag moves, and a moved tag breaks the
  output without a build change.
- Declare the memory. RFD 0026 gives the bf16 and the Q4_K_M figure
  per model.
- Name the license in `cog.yaml`. RFD 0028 gates what ships.
- Return a USD layer from every geometry Cog, and return the
  transmission file beside it. RFD 0053 gives that rule.

## Files in each folder

| File         | Holds                                        |
| ------------ | -------------------------------------------- |
| README.md    | The RFD. Why this model, and what it costs.  |
| cog.yaml     | The build, the CUDA version, and the weights.|
| predict.py   | `setup()`, `predict()`, and the type schema. |
| domain.ex    | A composite model only. See RFD 0037.        |
| problem.ex   | A composite model only. See RFD 0037.        |
| plan.ex      | The solved plan. The planner writes it.      |

## What a composite model does

Five models in the catalog run more than one network. RFD 0037 models
each one as a taskweft domain, and not as a Python script. The Cog
then calls the plan, and each step is one action.

## Related

RFD 0016 lists the models. RFD 0026 gives the memory. RFD 0037 gives
the composite convention. RFD 0053 gives the asset format. RFD 0028
gates the license.
