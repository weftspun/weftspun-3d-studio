# RFD 0043 details: the model, the interface, the open quality question

## The model

| Property   | Value                     |
| ---------- | ------------------------- |
| Parameters | 27.0 B, published         |
| bf16       | 54.0 GB, never built      |
| Q4_K_M     | 14.85 GB, the ship format |
| License    | Apache 2.0                |

The count covers the edit backbone and the vision language encoder
that reads the instruction. The encoder is not optional, because the
instruction is text and the edit is spatial.

## The interface

| Input       | Type  | Default |
| ----------- | ----- | ------- |
| image       | Path  | none    |
| instruction | str   | none    |
| strength    | float | 0.8     |
| steps       | int   | 20      |
| seed        | int   | -1      |

`instruction` is a sentence, and not a tag list. "Make the jacket red"
works. "jacket, red" does not, because the encoder reads language.

## The quality question stays open

No measurement compares Q4_K_M against bf16 for this model. The saving
is certain, and the quality cost is not.

Measure before the catalog depends on it. Run 20 edits in each format,
and compare them by eye. RFD 0027 permits both formats, thus a bf16
build stays legal if the measurement demands it.
