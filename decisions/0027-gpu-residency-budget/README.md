# RFD 0027: GPU residency budget

**State:** published
**Feature:** capacity planning

## Problem

RFD 0026 gives the memory per model in bf16. The sum is 116.45 GB, and
the DGX Spark holds 128 GB. The margin is about 10 GB, which the
activations and the allocator consume.

## Decision

Two weight formats are permitted. bf16 holds one parameter in 2 bytes,
and Q4_K_M holds one in about 0.55 bytes. No other format is
permitted, because each format adds a build path and a test path.

Quantize the two text-to-image models to Q4_K_M. Keep the other nine
models in bf16. That budget is 52.80 GB, and it leaves 75.20 GB.

## The three budgets

The catalog holds 58.225 B parameters in eleven neural models.

| Budget                          | Weights   | Free on 128 GB |
| ------------------------------- | --------: | -------------: |
| Every model in bf16             | 116.45 GB |       11.55 GB |
| Mixed, as decided above         |  52.80 GB |       75.20 GB |
| Every model in Q4_K_M           |  32.02 GB |       95.98 GB |

The mixed budget quantizes 43.9 B of the 58.225 B parameters. Those
need 24.15 GB in Q4_K_M, and not 87.80 GB. The other 14.325 B
parameters need 28.65 GB in bf16.

## Per pipeline

| Set                                | bf16     | Mixed    | Q4_K_M  |
| ---------------------------------- | -------: | -------: | ------: |
| Concept art to 3D (Krea, TRELLIS.2)|  41.80 GB| 17.30 GB | 11.50 GB|
| See-Through, local                 |   9.82 GB|  9.82 GB |  2.70 GB|
| Avatar (TRELLIS.2, SkinTokens)     |   9.00 GB|  9.00 GB |  2.48 GB|

The avatar pipeline and See-Through do not change under the mixed
budget. Neither one holds a text-to-image model.

## The budget has a hole

Two models carry no parameter count. `pixal3d_image_to_textured_mesh`
is one of them, and it is the image to 3D path in daily use.

Every total above therefore excludes the most used model. Treat
116.45 GB as a floor, and not as the answer. RFD 0040 gives the
measurement that closes this.

## What to do

- Quantize the text-to-image models first. Qwen and Krea hold 87.80 GB
  of the 116.45 GB, which is 75 percent of the catalog.
- Keep the geometry models in bf16. Together they hold 28.65 GB, thus
  quantization saves 20.77 GB and risks the mesh quality.
- Do not size a machine from these tables alone. Add the activation
  peak for the resolution and the batch size of each job.
- Prefer safetensors and memory mapping, because that removes the load
  transient.

## Related

RFD 0025 gives the arithmetic. RFD 0026 gives the memory per model.
RFD 0034 checks the arithmetic against a measured model.
