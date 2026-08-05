# RFD 0026: bf16 memory per model

**State:** published
**Feature:** capacity planning

## Problem

The backend must decide which models stay resident. That decision
needs a number per model.

## Decision

Apply the rule from RFD 0025 to each catalog model. Treat the
estimated rows as an upper bound for planning.

RFD 0027 permits two formats. bf16 holds one parameter in 2 bytes, and
Q4_K_M holds one in about 0.55 bytes. `DETAILS.md` gives both, per
model.

The Source column says where each number comes from. `published` means
the model card states the count. `measured` means this document read
the checkpoint sizes. `estimated` means this document derives the
count from the architecture. `unknown` means no count is available
yet.

Prefer `measured` over every other source, and prefer bf16 over fp16
where a checkpoint offers both. The two formats cost the same memory,
and bf16 carries the wider exponent range.

## Related

RFD 0025 gives the arithmetic. RFD 0027 gives the totals and the
consequence. RFD 0030 breaks down the See-Through row.
