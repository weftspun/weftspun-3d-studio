# RFD 0040: Cog for pixal3d_image_to_textured_mesh

**State:** discussion
**Feature:** model packaging

## Problem

Pixal3D is the image to 3D path in daily use. It writes a metal map
and a roughness map, which TRELLIS.2 does not.

This RFD first recorded its parameter count and its license as
unknown, and it asked for a measurement on the DGX. There is no DGX.
The measurement came from the published checkpoints instead.

## Decision

Package Pixal3D as the primary image to 3D Cog. Upstream is
TencentARC/Pixal3D, and it uses the MIT license.

Call the upstream `inference.py`, and do not reimplement the cascade.
A copy here would drift from the commit this Cog pins.

## The measurement

Seven checkpoints, 24.045 GB on disk. Every file is fp16 or bf16, and
both hold one parameter in 2 bytes, thus the count is 12.02 B.

| Checkpoint                            |     Size | Stage            |
| ------------------------------------- | -------: | ---------------- |
| slat_flow_img2shape_dit_1_3B_1024     | 5.547 GB | shape 1024       |
| slat_flow_img2shape_dit_1_3B_512      | 5.547 GB | shape 512        |
| slat_flow_imgshape2tex_dit_1_3B_1024  | 5.547 GB | texture 1024     |
| ss_flow_img_dit_1_3B_64               | 5.360 GB | sparse structure |
| shape_dec_next_dc_f16c32              | 0.948 GB | shape decode     |
| tex_dec_next_dc_f16c32                | 0.948 GB | texture decode   |
| ss_dec_conv3d_16l8                    | 0.148 GB | structure decode |
| **total**                             | **24.045 GB** |             |

The file names say `1_3B`, and each DiT file is 5.5 GB. At 2 bytes per
parameter that is 2.77 B, and not 1.3 B. The measured size is the
fact this RFD records. The name may count the transformer alone, and
leave out an encoder the file also carries.

## Prefer bf16

The four DiTs ship bf16, and the three decoders ship fp16. Take bf16
wherever a checkpoint offers both.

The two formats cost the same memory, thus this is not a budget
choice. bf16 carries the wider exponent range, and a diffusion cascade
that overflows in one stage feeds the fault to the next.

The decoders ship fp16 only. No choice exists there yet.

## The cascade never needs one resident set

Three stages run in order, and each frees before the next loads.
`--low_vram` makes that explicit, and it drops the peak from 24.045 GB
to about 6.5 GB, which is one DiT plus a decoder.

Keep `low_vram` on. A 24 GB card then runs this model, and the cost
per second falls with the card.

## The interface

| Input      | Type  | Default |
| ---------- | ----- | ------- |
| image      | Path  | none    |
| seed       | int   | 42      |
| fov        | float | -1.0    |
| resolution | int   | -1      |
| low_vram   | bool  | true    |

`fov` of -1.0 lets MoGe estimate the field of view. The output is not
one file. RFD 0053 makes USD the internal format, thus `predict()`
returns a layer beside the GLB.

## Three repositories download at build time

`TencentARC/Pixal3D` is 24.045 GB. `Ruicheng/moge-2-vitl` estimates
the field of view. `camenduru/dinov3-vitl16-pretrain-lvd1689m` is the
conditioning encoder, and all four stages read it.

A cold start that downloads 24 GB is a cold start that times out.

## What this corrects

- The license is MIT, and not unknown. RFD 0028 gates on that, and
  Pixal3D clears the gate.
- The count is 12.02 B, and not unknown. RFD 0026 carried one of two
  unknown rows for this model.
- The backbone is TRELLIS.2, per the upstream README. RFD 0038
  packages TRELLIS.2, thus these two Cogs share a lineage.

## Related

RFD 0026 gives the memory per model. RFD 0027 gives the GPU tier.
RFD 0038 packages the backbone. RFD 0053 gives the asset format.
