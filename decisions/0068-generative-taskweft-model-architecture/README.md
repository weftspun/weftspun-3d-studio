# RFD 0068: A generative taskweft model, and which architecture

**State:** prediscussion
**Scope:** RFD 0064's domain/problem authoring step

## Problem

RFD 0064 has Claude write each `problem.ex` by hand, one dataset row
at a time. A trained model that generates a `domain.ex`/`problem.ex`
pair from a caption, with no per-row Claude call, would remove that
per-row cost. Two sequence-model architectures came up as candidates:
Differential Mamba (arXiv:2507.06204, `thirdparty/2507.06204v2.pdf`)
and FuXi-Linear (arXiv:2602.23671, KDD 2026).

## Decision

Not yet made. Record the rerank, and defer a choice.

Differential Mamba targets general language modeling, reducing
attention overallocation for long-context retrieval. A generative
taskweft model would need it as a text/token backbone, since taskweft
domains are structured JSON-LD, closer to code than to prose.

FuXi-Linear targets long-term time-aware sequential recommendation.
Its two channels split temporal and semantic signal over a user's
item history. A taskweft domain carries no comparable temporal
sequence, so this fit is weaker than Differential Mamba's.

Neither is a ready fit. Gall's law is the stronger argument here.
RFD 0064's per-row Claude call already works, and already runs. A
from-scratch trained model is a large, unproven bet against a
process this project has not yet shown insufficient. See
`DETAILS.md` for the fuller comparison and the trigger condition to
revisit.

## Related

RFD 0064 is the per-row authoring step this RFD would replace. RFD
0066 abandons a related use of Differential Mamba, for RFD 0065's
resolve step, on similar grounds.
