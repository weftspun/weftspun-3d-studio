# RFD 0034 details: the estimate table and the result

## The estimate

| Part               | Parameters | bf16 weights |
| ------------------ | ---------: | -----------: |
| diffusion backbone |     12.0 B |      24.0 GB |
| T5 text encoder    |      4.7 B |       9.4 GB |
| CLIP text encoder  |     0.12 B |      0.24 GB |
| VAE                |     0.08 B |      0.16 GB |
| **total**          | **16.9 B** |  **33.8 GB** |

## The result

The 32 GB reserve agrees with 33.8 GB. The worker does not hold every
part at the same time.

The 57 GB on disk is larger than 33.8 GB. The folder carries fp32
copies as well, thus the disk size is not the load size.

This agreement raises the confidence in the method. It does not raise
the confidence in the parameter counts of the other models. Replace
each estimated count with a measured count from `config/models.yaml`
on the DGX.
