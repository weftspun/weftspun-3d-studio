# RFD 0066: Differential Mamba for caption encoding

**State:** abandoned
**Scope:** RFD 0065's trait resolve step

## Problem

RFD 0065 resolves a dataset caption to a trait capability id through
`HRR`/`HRR.Cleanup`. A question came up: does Differential Mamba
(Schneider, Zimerman, and Nachmani, arXiv:2507.06204), a sequence
model architecture, improve that step.

## Decision

Do not adopt it. Abandon this line of work.

Differential Mamba reduces attention overallocation in a trained,
autoregressive language model, for long-context retrieval. RFD
0065's resolve step needs none of that. `HRR.encode_atom/2` is a
closed-form hash into a phase vector, with no training step and no
sequence to attend over. `HRR.Cleanup.nearest_above/3` compares that
vector against a codebook by cosine similarity.

RFD 0021 already chose this closed-form algebra over a trained model,
for the same reason a fact vector needs no LLM. A sequence model here
would trade an exact, cheap, verified mechanism for a trained one.
That trained model solves a problem this step does not have.

## Related

RFD 0065 owns the resolve step this RFD examined. RFD 0021 gives the
`HRR` library and the earlier closed-form-over-trained-model choice.
