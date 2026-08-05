# RFD 0068 details: the two candidates, and the trigger to revisit

## Differential Mamba (arXiv:2507.06204)

Schneider, Zimerman, and Nachmani. A differential mechanism for
Mamba, a selective state-space sequence architecture, cutting
over-allocation of attention to irrelevant context. Validated on
language modeling benchmarks: better retrieval and long-context
robustness than vanilla Mamba.

This is a general autoregressive language model backbone. It reads
and writes token sequences, with no notion of a structured schema.
Applying it to taskweft generation means treating a `domain.ex` file
as text, tokenizing it, and training a model to predict the next
token. That is the same shape any code-generating LLM uses today,
with a Mamba backbone in place of a Transformer one.

## FuXi-Linear (arXiv:2602.23671, KDD 2026)

USTC-StarTeam. A linear-complexity attention model for long-term
time-aware sequential recommendation. It carries two channels. A
Temporal Retention Channel computes periodic attention weights from
timestamps, kept separate from semantic signal. A Linear Positional
Channel carries position through learnable kernels. Both target
thousand-length user interaction histories, with O(n) training and
O(1) decode.

Its whole design decouples "what a user picked" from "when they
picked it," across a long ranked sequence of past choices. A
taskweft domain has no analogous history to model. `@variables`,
`@actions`, and `@todo_list` are a small, finite, structured
document, not a long temporal sequence of prior events. FuXi-Linear's
core contribution does not transfer.

## Why this stays prediscussion

Both candidates are sequence-model architectures, and a generative
taskweft model needs training data first: pairs of (caption,
domain.ex/problem.ex) at a scale a model can learn from. RFD 0064
produces zero such pairs today, because it uses Claude's own per-row
authoring instead. There is no training set yet, so ranking an
architecture ahead of a training set is a decision with nothing to
decide against.

## The trigger to revisit

Revisit this RFD once RFD 0064 produces problem.ex files for a
meaningful share of the 15,000 dataset rows. Revisit it once the
per-row Claude cost is a measured, named bottleneck, not a guessed
one. At that point the actual shape of the training pairs (short,
structured JSON-LD, not long token sequences) should drive the
architecture choice, more than either paper's own benchmark domain
does.

## Sources

- Schneider, N., Zimerman, I., and Nachmani, E. "Differential
  Mamba." arXiv:2507.06204. `thirdparty/2507.06204v2.pdf`.
- USTC-StarTeam. "FuXi-Linear: Unleashing the Power of Linear
  Attention in Long-term Time-aware Sequential Recommendation."
  arXiv:2602.23671, KDD 2026. https://github.com/USTC-StarTeam/fuxi-linear
