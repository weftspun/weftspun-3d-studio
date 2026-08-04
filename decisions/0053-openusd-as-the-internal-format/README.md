# RFD 0053: OpenUSD as the internal format

**State:** discussion
**Feature:** asset interchange

## Problem

Each pipeline stage reads a GLB and writes a GLB. A rig stage rewrites
the whole file to add bones. A texture stage rewrites it again.

Every rewrite loses what came before. glTF holds one flat result, thus
a stage cannot add an opinion without erasing the previous author.
When a mesh is wrong, no record says which stage made it wrong.

## Decision

OpenUSD is the internal format. Every stage reads a stage and writes a
layer. glTF, VRM, and KHR avatar stay the transmission formats, and
the pipeline converts to them at the edge.

USD is to this pipeline what `.blend` is to Blender. It is the working
file, and it never reaches a browser.

## Why layers, and not a better mesh format

USD composes. A stage adds a sublayer with its own opinion, and the
layer below stays intact and readable.

| Stage        | Writes                                  |
| ------------ | --------------------------------------- |
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
| --------- | ---------------------------- |
| Internal  | `.usdc`, and `.usda` to read |
| Avatar out| VRM, or KHR avatar           |
| Asset out | glTF binary                  |
| Archive   | `.usdz`                      |

Convert at the boundary only. A stage that converts in the middle
throws away the composition this RFD exists to keep.

## The runtime

`fabric-stage-runtime` ships OpenUSD 26.5.0 as an Elixir Hex package.
It exposes `include_dir/0`, `lib_dir/0`, and `target/0`, thus the
Elixir core from RFD 0019 links the same USD build the Cogs write.

One USD version across the pipeline matters. A layer written by a
newer build may not open in an older one.

## What each Cog must do

`predict()` returns the USD layer, and it returns the transmission
file as well. The caller keeps the layer, and it ships the other.

RFD 0036 records this in the Cog convention.

## Related

RFD 0036 gives the Cog convention. RFD 0019 records the Elixir core
that links this runtime. RFD 0002 records the pipeline stages that
become layers.
