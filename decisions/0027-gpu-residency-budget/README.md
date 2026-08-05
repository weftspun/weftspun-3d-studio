# RFD 0027: GPU tier per model

**State:** discussion
**Feature:** capacity planning

## Problem

This RFD first asked whether every model fits one device at once. It
summed 116.45 GB against a 128 GB DGX Spark, found about 10 GB of
headroom, and called the margin too small.

That question came from hardware this project does not have. There is
no DGX. Replicate runs each model in its own container on its own GPU,
thus two models never compete for one device.

The old finding was an artifact. This RFD replaces it.

## Decision

Size each model on its own. The question is which GPU tier one model
needs, and not whether a set of models co-resides.

Two numbers decide the tier: the weights RFD 0026 gives per model,
and the activation peak, which depends on the resolution and the
batch size.

Every model in the catalog reaches a 24 GB card, once staged loading
frees each stage's weights before the next stage loads. See
`DETAILS.md` for the tier table, the staging reasoning, the
quantization cost tradeoff, and the resulting checklist.

## Related

RFD 0025 gives the arithmetic. RFD 0026 gives the memory per model.
RFD 0036 gives the Cog packaging that sets the tier.
