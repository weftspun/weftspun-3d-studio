# RFD 0025: Model memory arithmetic

**State:** published
**Feature:** capacity planning

## Problem

RFD 0016 says what each model is. It does not say what each model
costs. A reader cannot size a machine from the inventory alone.

## Decision

Compute the memory from the parameter count. RFD 0026 records the
result per model.

## The rule

bf16 holds one parameter in 2 bytes. The weight bytes are therefore
the parameter count multiplied by 2.

```
weight bytes = parameters x 2
weight GB    = parameters in billions x 2
```

This document counts 1 GB as 1,000,000,000 bytes. The GiB figure is
smaller by 7 percent.

See `DETAILS.md` for the three costs that come after the weights,
and the safe rule for one resident model.

## Related

RFD 0016 lists the models. RFD 0026 applies this rule to each one.
RFD 0034 checks the rule against a measured model.
