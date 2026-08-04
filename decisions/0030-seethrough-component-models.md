# RFD 0030: See-Through component models

**State:** published
**Feature:** layer decomposition

## Problem

The `seethrough_layer_decomposition` entry names one task. The task
runs nine models. One catalog row hides that fact.

## Decision

Name each component here. Record its base model, its role, and its
memory.

## The components

| Component      | Base model          | Role                 | Parameters | bf16    |
| -------------- | ------------------- | -------------------- | ---------: | ------: |
| layerdiff-unet | SDXL UNet           | Generates layers     |    2.567 B | 5.13 GB |
| marigold-unet  | Marigold            | Depth estimate       |    0.865 B | 1.73 GB |
| layerdiff-te2  | CLIP text encoder 2 | Prompt encode        |    0.695 B | 1.39 GB |
| marigold-te    | CLIP text encoder   | Depth conditioning   |    0.340 B | 0.68 GB |
| layerdiff-te1  | CLIP text encoder   | Prompt encode        |    0.123 B | 0.25 GB |
| trans-vae      | TransparentVAE      | Alpha decode         |    0.100 B | 0.20 GB |
| layerdiff-vae  | SDXL VAE            | Latent decode        |    0.084 B | 0.17 GB |
| marigold-vae   | Marigold VAE        | Depth decode         |    0.084 B | 0.17 GB |
| lama           | LaMa                | Inpaints hidden area |    0.051 B | 0.10 GB |
| **total**      |                     |                      |  **4.9 B** | 9.82 GB |

## Two runtimes

The DGX API runs the Cog model from RFD 0006. see-through.cpp runs the
same models on a local machine, with ggml and a Vulkan backend. It
reads GGUF weights and writes a layered PSD. It needs no DGX
connection, and it uses the Apache 2.0 license.

## bf16 is the ceiling, and GGUF is the floor

The local runtime does not use bf16. Q4_K_M holds one parameter in
about 0.55 bytes, thus the same nine components need about 2.7 GB.
Plan the DGX path against 9.82 GB. Plan the local path against 2.7 GB.

## Related

RFD 0006 records the layer decomposition design. RFD 0019 selects the
same ggml runtime for the Elixir core. RFD 0026 carries the single
catalog row that this RFD breaks down.
