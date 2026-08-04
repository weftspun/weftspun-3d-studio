# RFD 0044: Cog for seethrough_layer_decomposition

**State:** discussion
**Feature:** model packaging

## Problem

This entry names one task and runs nine networks. RFD 0030 lists them.
A Python script that calls them in order hides the order, the guards,
and the point where a failure happened.

Nine networks need 9.82 GB together in bf16. They do not all need to
be resident, because a text encoder finishes before the UNet starts.

## Decision

Model the pipeline as a taskweft domain, and let the planner pick the
order. `domain.ex` and `problem.ex` in this folder hold it.
RFD 0037 gives the convention, and both files validate against
`Code.string_to_quoted/1`.

The Cog calls `plan`, and it runs one function per action. The order
lives in the domain, thus a pipeline change edits `domain.ex` and not
Python.

## Why a planner earns its place here

The domain carries `a_load` and `a_unload` as real actions. The peak
memory is then a planning result, and not an accident.

`make_depth` does not read the layer output. Marigold runs on the
original image, thus the planner may order it before or after
`make_layers`. A hand-written script fixes one order forever.

## The nine, and their guards

| Action           | Needs                        |
| ---------------- | ---------------------------- |
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

## Related

RFD 0037 gives the convention. RFD 0030 lists the components. RFD 0006
records the design.
