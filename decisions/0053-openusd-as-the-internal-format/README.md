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

See `DETAILS.md` for why layers beat a flat mesh format, the
internal/transmission boundary, the shared runtime, and what every
Cog must return.

## Related

RFD 0036 gives the Cog convention. RFD 0019 records the Elixir core
that links this runtime. RFD 0002 records the pipeline stages that
become layers.
