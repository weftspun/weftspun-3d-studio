# RFD 0042: Model image for krea2_turbo_text_to_image

**State:** discussion
**Feature:** model packaging

## Problem

Krea 2 Turbo is the largest model in the catalog that the project
runs. It needs 33.8 GB in bf16, which is 29 percent of the whole
catalog.

It is also four models in one folder: a backbone, two text encoders, and
a VAE. A model image that loads all four at once wastes memory, because
the text encoders finish before the backbone starts.

## Decision

Package it as one model image, and stage the loads. The text encoders
load, they run, and they unload. The backbone then loads.

Quantize to Q4_K_M. RFD 0027 selects that format for both
text-to-image models, and it drops this one from 33.8 GB to 9.30 GB.

See `DETAILS.md` for the model's per-part memory, the `predict()`
interface, and the disk-size trap in the weight folder.

## Related

RFD 0027 selects the format. RFD 0034 checks the arithmetic. RFD 0025
gives the rule.
