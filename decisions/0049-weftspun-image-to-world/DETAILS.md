# RFD 0049 details: the model, the interface, why the planner earns its place

## The model

| Part       | Source   | bf16    |
| ---------- | -------- | ------: |
| TripoSplat | RFD 0052 | 2.2 GB  |
| TRELLIS.2  | RFD 0038 | 8.0 GB  |
| **total**  |          | 10.2 GB |

The two never need to be resident together. The domain carries
`a_load` and `a_unload`, thus the peak is 8.0 GB and not 10.2 GB.

## The interface

| Input          | Type | Default |
| -------------- | ---- | ------- |
| image          | Path | none    |
| prop_count     | int  | 0       |
| prop_prompts   | str  | ""      |
| seed           | int  | -1      |

`prop_count` of 0 gives the environment only. That is the common case,
and it must not pay for the TRELLIS.2 load.

## Why the planner earns its place

`prop_count` decides whether TRELLIS.2 runs at all. A method
alternative checks it, thus the plan for an environment-only job never
mentions the mesh model.

A script would load it and then skip it.
