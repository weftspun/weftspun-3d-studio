# RFD 0037: Composite models as taskweft domains

**State:** discussion
**Feature:** model packaging

## Problem

Five catalog entries name one task and run several networks.
`seethrough_layer_decomposition` runs nine. A Python script that calls
them in order hides the order, the guards, and the failure points.

A script also cannot replan. When a stage fails, the caller repeats
the whole job.

## Decision

Model each composite as a taskweft domain and a paired problem.
taskweft is an HTN planner at github.com/taskweft/taskweft, and it
serves `plan` and `validate` over MCP at
https://taskweft-mcp.fly.dev/mcp.

Write the domain in the Elixir DSL. The `plan` tool takes `format` of
`dsl` by default, and JSON-LD is the fallback. Each file is real
Elixir, thus `Code.string_to_quoted/1` checks it with no planner.

The model image then calls the plan, and it runs one action per step. The
order lives in the domain, and not in the Python.

See `DETAILS.md` for the domain shape and the type rules. It also
covers why the solved plan is a checked-in file, why replanning is
the payoff, and the table of all five composites.

## Related

RFD 0036 gives the model image convention. RFD 0030 lists the See-Through
components. RFD 0006 records the layer decomposition design.
