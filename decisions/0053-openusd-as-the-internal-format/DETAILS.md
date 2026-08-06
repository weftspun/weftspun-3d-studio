# RFD 0053 details: layers, the boundary, the runtime, the model image contract

## Why layers, and not a better mesh format

USD composes. A stage adds a sublayer with its own opinion, and the
layer below stays intact and readable.

| Stage        | Writes                                  |
| ------------- | ----------------------------------------|
| image to 3D  | the base mesh layer                     |
| retopology   | a layer that overrides the mesh         |
| UV unwrap    | a layer that adds the primvar           |
| segmentation | a layer of part scopes                  |
| rig          | a layer of skeleton and skin bindings   |
| texture      | a layer of material bindings            |

A caller may then mute the retopology layer and see the original. That
is not possible in a flat file.

## The boundary

| Direction | Format                       |
| --------- | ----------------------------- |
| Internal  | `.usdc`, and `.usda` to read |
| Avatar out| VRM, or KHR avatar           |
| Asset out | glTF binary                  |
| Archive   | `.usdz`                      |

Convert at the boundary only. A stage that converts in the middle
throws away the composition this RFD exists to keep.

## The runtime

`fabric-stage-runtime` ships OpenUSD 26.5.0 as an Elixir Hex package.
It exposes `include_dir/0`, `lib_dir/0`, and `target/0`, thus the
Elixir core from RFD 0019 links the same USD build the model images write.

One USD version across the pipeline matters. A layer written by a
newer build may not open in an older one.

## What each model image must do

`predict()` returns the USD layer, and it returns the transmission
file as well. The caller keeps the layer, and it ships the other.

RFD 0036 records this in the model image convention.
