# RFD 0030: See-Through component models

**State:** published
**Feature:** layer decomposition

## Problem

The `seethrough_layer_decomposition` entry names one task. The task
runs nine models. One catalog row hides that fact.

## Decision

Name each component here. Record its base model, its role, and its
memory.

See `DETAILS.md` for the component table, the two runtimes, and why
bf16 is the ceiling while GGUF is the floor.

## Related

RFD 0006 records the layer decomposition design. RFD 0019 selects the
same ggml runtime for the Elixir core. RFD 0026 carries the single
catalog row that this RFD breaks down.
