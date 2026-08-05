# RFD 0044 details: why a planner, the nine actions, two runtimes

## Why a planner earns its place here

The domain carries `a_load` and `a_unload` as real actions. The peak
memory is then a planning result, and not an accident.

`make_depth` does not read the layer output. Marigold runs on the
original image, thus the planner may order it before or after
`make_layers`. A hand-written script fixes one order forever.

## The nine, and their guards

| Action           | Needs                        |
| ---------------- | ----------------------------- |
| a_inpaint        | lama, the image              |
| a_encode_prompt  | layerdiff_te1, layerdiff_te2 |
| a_diffuse_layers | the embeds, the inpaint      |
| a_decode_rgb     | the latents                  |
| a_decode_alpha   | the latents                  |
| a_depth_encode   | marigold_te, marigold_unet   |
| a_depth_decode   | the depth latents            |
| a_write_psd      | rgb, alpha, and depth        |

`a_decode_rgb` and `a_decode_alpha` read the same latents. That is the
one fact a reader of the old script always missed.

## Two runtimes, one domain

RFD 0030 records a DGX path at 9.82 GB in bf16, and a local ggml path
at about 2.7 GB in Q4_K_M. The domain does not change between them.
Only the action bodies change.
