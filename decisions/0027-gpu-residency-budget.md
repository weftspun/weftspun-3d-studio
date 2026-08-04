# RFD 0027: GPU residency budget

**State:** published
**Feature:** capacity planning

## Problem

RFD 0026 gives the memory per model. The sum of those numbers decides
whether the backend can hold every model at the same time.

## Decision

The backend must not hold every model resident. It must load a model
per job, or it must quantize.

## The totals

| Set                                        | bf16 weights |
| ------------------------------------------ | -----------: |
| Every catalog model, resident at once      |    116.45 GB |
| The same set, with the Hunyuan models      |    125.65 GB |
| Concept art to 3D (Krea 2 Turbo, TRELLIS.2)|     41.80 GB |
| Avatar (TRELLIS.2, SkinTokens)             |      9.00 GB |
| See-Through, local                         |      9.82 GB |

## The margin is too small

The DGX Spark holds 128 GB of unified memory. The full catalog in bf16
needs 116 GB. That leaves about 10 GB for the activations, the
allocator, and the operating system.

The two large text-to-image models are the cause. Together they need
87.8 GB, which is 75 percent of the catalog. Qwen ships as Q4_K_M for
this reason. At 0.55 bytes per parameter it needs 14.9 GB, and not
54.0 GB. That single choice saves 39 GB.

## What to do

- Do not size a machine from the table alone. Add the activation peak
  for the resolution and the batch size of each job.
- Prefer safetensors and memory mapping, because that removes the load
  transient.
- Quantize the text-to-image models first, because they hold most of
  the weight.

## Related

RFD 0025 gives the arithmetic. RFD 0026 gives the memory per model.
RFD 0034 checks the arithmetic against a measured model.
