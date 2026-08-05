# RFD 0047 details: the model, the interface, the guard, layering

## The model

| Property   | Value                             |
| ---------- | ----------------------------------|
| Parameters | 0. It shares the RFD 0038 weights |
| bf16       | 8.0 GB, the RFD 0038 cost         |
| License    | MIT                               |

## The interface

| Input       | Type | Default |
| ----------- | ---- | ------- |
| mesh        | Path | none    |
| instruction | str  | none    |
| region      | Path | none    |
| seed        | int  | -1      |

`region` is a mask. RFD 0028 records the supported mask list in
decisions/api/api.md.

## The unmasked region must not move

Inversion is lossy. A decode of an unedited latent does not give back
the input mesh exactly, thus a naive implementation moves vertices the
user never selected.

The domain states this as a guard. `a_decode` requires
`/have/preserved_outside`, and `a_splice` sets it by pasting the
original geometry back outside the mask.

That guard is the whole reason this model is a composite here.

## Layers make the edit reversible

RFD 0053 gives the rule. The edit is a sublayer over the source mesh,
thus a caller mutes the layer and gets the original back. A flat file
makes the edit permanent.
