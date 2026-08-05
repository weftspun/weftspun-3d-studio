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

Two numbers decide the tier. The weights, which RFD 0026 gives per
model. The activation peak, which depends on the resolution and the
batch size.

## Tier per model

A tier must hold the weights and the activations together. The Peak
column is the resident weight set, which is smaller than the total for
a model that runs in stages.

| Model                          | Weights  | Peak     | Tier  |
| ------------------------------ | -------: | -------: | ----- |
| qwen_q4_k_m_image_edit         | 14.85 GB | 14.85 GB | 24 GB |
| pixal3d_image_to_textured_mesh | 24.05 GB |  6.50 GB | 24 GB |
| krea2_turbo_text_to_image      |  9.30 GB |  9.30 GB | 24 GB |
| seethrough_layer_decomposition |  9.82 GB |  5.13 GB | 24 GB |
| trellis2_image_to_textured_mesh|  8.00 GB |  8.00 GB | 24 GB |
| worldmirror2_reconstruct       |  2.40 GB |  2.40 GB | 24 GB |
| triposplat_image_to_splat      |  2.20 GB |  2.20 GB | 24 GB |
| skintokens_auto_rig            |  1.00 GB |  1.00 GB | 24 GB |
| p3sam_mesh_segmentation        |  0.80 GB |  0.80 GB | 24 GB |
| kimodo_text_to_motion          |  0.60 GB |  0.60 GB | 24 GB |

Every model reaches a 24 GB card. That is the finding, and it is the
opposite of what this RFD first recorded.

## Staging is what makes the tier

Pixal3D holds 24.05 GB and peaks at 6.50 GB. Three stages run in
order, and each frees before the next loads. Without that staging it
would need an 80 GB card.

See-Through holds 9.82 GB and peaks at 5.13 GB, for the same reason.
RFD 0044 makes the load and the unload real actions, thus the peak is
a planning result.

A Cog that loads every stage at once pays for a larger card every
second it runs.

## Quantization is now a cost choice

On one shared device, quantization decided what fit. On Replicate it
decides what a second costs.

Qwen at 54.0 GB in bf16 needs an 80 GB card. At 14.85 GB in Q4_K_M it
needs 24 GB. Both run, and the tiers differ in price.

Measure the quality cost before the catalog depends on it. RFD 0043
records that no such measurement exists yet.

## What to do

- Size each model alone. A set total means nothing here.
- Stage the loads, and report the peak and not the sum.
- Prefer bf16 over fp16 where a checkpoint offers both. The memory is
  the same, and bf16 carries the wider exponent range.
- Add the activation peak for the resolution and the batch size of
  each job. The tiers above count weights only.

## Related

RFD 0025 gives the arithmetic. RFD 0026 gives the memory per model.
RFD 0036 gives the Cog packaging that sets the tier.
