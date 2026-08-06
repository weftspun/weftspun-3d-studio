# RFD 0042 details: the model, the interface, the disk trap

## The model

| Part               | Parameters | bf16     | Q4_K_M  |
| ------------------ | ---------: | -------: | ------: |
| diffusion backbone |     12.0 B |  24.0 GB | 6.60 GB |
| T5 text encoder    |      4.7 B |   9.4 GB | 2.59 GB |
| CLIP text encoder  |     0.12 B |  0.24 GB | 0.07 GB |
| VAE                |     0.08 B |  0.16 GB | 0.04 GB |
| **total**          | **16.9 B** | **33.8 GB** | **9.30 GB** |

RFD 0034 checks the bf16 column against the 32 GB worker reserve.

## The interface

| Input           | Type  | Default |
| ---------------- | ----- | ------- |
| prompt          | str   | none    |
| negative_prompt | str   | ""      |
| width           | int   | 1024    |
| height          | int   | 1024    |
| steps           | int   | 4       |
| seed            | int   | -1      |

The step default is 4, because this is the Turbo variant. A caller
that asks for 30 steps gets no better image, and pays 7 times.

## The disk trap

The weight folder is 57 GB. That is not the load size. It carries fp32
copies, and the model image must read the bf16 set only. A build that
copies the whole folder makes a 57 GB image for a 9.30 GB model.