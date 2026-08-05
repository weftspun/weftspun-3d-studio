# RFD 0068 details: the three candidates, and the trigger to revisit

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

## Gemma 4 (small variants)

Google. A general-purpose model family, shipped at several sizes.
The small tiers matter here. E2B and E4B use the "effective
parameter" naming Gemma 3n first used. A 26B-A4B mixture-of-experts
tier also exists. There, 26B is the total weight count, and 4B is
the count active per token.

RFD 0026 and RFD 0027 already size this project's own catalog
models in bf16 gigabytes, against a 24 GB card. Every Gemma 4 small
tier clears that bar.

Unlike the other two candidates, Gemma 4 starts pretrained, on text
and code both. Fine-tuning it for `domain.ex`/`problem.ex`
generation is a narrow adaptation, of a model that already knows
Elixir-shaped and JSON-shaped syntax. It is not a new architecture
learning syntax from zero. That needs a far smaller labeled set than
training Differential Mamba or FuXi-Linear from scratch would need.

### A ready fine-tune, and where it can run

`yuxinlu1/gemma-4-12B-agentic-fable5-composer2.5-v2-3.5x-tau2`, on
Hugging Face, fine-tunes `google/gemma-4-12B-it` for coding,
agentic, and tool-use work. Apache-2.0, so it clears RFD 0028's
license gate. 266,452 downloads and 84 likes as of this RFD.

The 12B parameter count does not clear RFD 0027's local card
budget. bf16 holds 2 bytes per parameter, so 12B needs about 24 GB
for weights alone. That leaves no room for a KV cache or
activations, on the RTX 4090 this project owns.

Fireworks AI's custom-model upload accepts a full model like this
one, not only a LoRA adapter. It serves that upload from an
on-demand deployment, queried the same way a serverless endpoint is
queried, with no local VRAM at all. Serverless deployment is not
open to a custom upload. Only on-demand is. Running this fine-tune
means a hosted GPU this project rents by the deployment, not the
4090 it already owns. RFD 0055 and RFD 0062 already weigh that same
rented-versus-owned trade, for other models.

## Why this stays prediscussion

All three candidates need training data: pairs of (caption,
domain.ex/problem.ex). RFD 0064 produces zero such pairs today,
because it uses Claude's own per-row authoring instead. Fine-tuning
Gemma 4 lowers the bar. A from-scratch architecture needs a large
learning set. Gemma 4 needs a few hundred real examples instead. The
bar is not zero either way, and RFD 0064 has not cleared it yet.

## The trigger to revisit

For fine-tuning Gemma 4, revisit this RFD once RFD 0064 produces a
few hundred real `problem.ex` files. That bar is lower than a
meaningful share of the 15,000 dataset rows. For training
Differential Mamba or FuXi-Linear from scratch, keep the higher bar.
That needs a measured, named per-row Claude cost, and a dataset
large enough to train an architecture from empty weights. At that
point the actual shape of the training pairs (short, structured
JSON-LD, not long token sequences, and not a long
user-interaction history) should drive the choice, more than any one
paper's own benchmark domain does.

## Sources

- Schneider, N., Zimerman, I., and Nachmani, E. "Differential
  Mamba." arXiv:2507.06204. `thirdparty/2507.06204v2.pdf`.
- USTC-StarTeam. "FuXi-Linear: Unleashing the Power of Linear
  Attention in Long-term Time-aware Sequential Recommendation."
  arXiv:2602.23671, KDD 2026. https://github.com/USTC-StarTeam/fuxi-linear
- Google. Gemma 4 model family, small tiers E2B, E4B, and 26B-A4B.
- yuxinlu1. `gemma-4-12B-agentic-fable5-composer2.5-v2-3.5x-tau2`.
  https://huggingface.co/yuxinlu1/gemma-4-12B-agentic-fable5-composer2.5-v2-3.5x-tau2
- Fireworks AI. "Custom Models."
  https://docs.fireworks.ai/models/uploading-custom-models
