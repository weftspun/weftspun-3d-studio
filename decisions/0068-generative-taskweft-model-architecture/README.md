# RFD 0068: A generative taskweft model, and which architecture

**State:** prediscussion
**Scope:** RFD 0064's domain/problem authoring step

## Problem

RFD 0064 has Claude write each `problem.ex` by hand, one dataset row
at a time. A trained model that generates a `domain.ex`/`problem.ex`
pair from a caption, with no per-row Claude call, would remove that
per-row cost. Three candidates came up: training Differential Mamba
(arXiv:2507.06204) from scratch, training FuXi-Linear (arXiv:2602.23671,
KDD 2026) from scratch, and fine-tuning a small Gemma 4 variant.

## Decision

Not yet made. The rerank now favors fine-tuning Gemma 4, over
training either other candidate from scratch.

Differential Mamba targets general language modeling. FuXi-Linear
targets long-term time-aware sequential recommendation, over a
user's item history a taskweft domain does not have. Both start
from empty weights, and both need a training set this project does
not hold yet. See `DETAILS.md` for the full comparison.

Gemma 4 ships small variants. The E2B/E4B tier and the 26B-A4B
mixture-of-experts tier both fit RFD 0027's 24 GB card budget. A
pretrained model already reads and writes code and JSON. Fine-tuning
it needs far fewer labeled pairs than training an architecture from
scratch needs. A ready agentic fine-tune also exists, at the 12B
tier, over that card budget locally, but within reach on Fireworks
AI's hosted, on-demand deployments. See `DETAILS.md` for both paths
and the revised trigger.

## Related

RFD 0064 is the per-row authoring step this RFD would replace. RFD
0027 sets the 24 GB card budget Gemma 4's small variants fit. RFD
0066 abandons a related use of Differential Mamba, for RFD 0065's
resolve step, on similar grounds.
