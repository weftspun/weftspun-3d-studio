# RFD 0044: Model image for seethrough_layer_decomposition

**State:** discussion
**Feature:** model packaging

## Problem

This entry names one task and runs nine networks. RFD 0030 lists them.
A Python script that calls them in order hides the order, the guards,
and the point where a failure happened.

Nine networks need 9.82 GB together in bf16. They do not all need to
be resident, because a text encoder finishes before the UNet starts.

## Decision

Model the pipeline as a taskweft domain, and let the planner pick the
order. `domain.ex` and `problem.ex` in this folder hold it.
RFD 0037 gives the convention, and both files validate against
`Code.string_to_quoted/1`.

The model image calls `plan`, and it runs one function per action. The
order lives in the domain, thus a pipeline change edits `domain.ex` and
not Python.

See `DETAILS.md` for why a planner earns its place here, the nine
actions and their guards, and how one domain covers both runtimes.

## Related

RFD 0037 gives the convention. RFD 0030 lists the components. RFD 0006
records the design.
