# RFD 0045 details: the model, the interface, the validation gate

## The model

| Property   | Value            |
| ---------- | ---------------- |
| Parameters | 0.3 B, estimated |
| bf16       | 0.6 GB           |
| Q4_K_M     | 0.17 GB          |
| Format     | bf16             |

## The interface

| Input          | Type  | Default |
| -------------- | ----- | ------- |
| prompt         | str   | none    |
| duration_seconds | float | 4.0   |
| fps            | int   | 30      |
| target_rig     | Path  | none    |
| seed           | int   | -1      |

`target_rig` is optional. Without it the model image returns SOMA
only, and it runs no retarget.

## The validation gate

RFD 0007 records the motion validation. A motion that leaves the floor
or that inverts a knee must fail here, and not in the viewport.

Run the validation inside this model image, and return its verdict as a
field. A caller then knows the motion is unusable before it loads it.