# RFD 0073: A billboard gallery of the RFD 0064 dataset, in one USD stage

**State:** prediscussion
**Scope:** RFD 0064's dataset, `usd_viewer_app/`

## Problem

RFD 0064's dataset holds about 15,000 anime images and captions, on
disk, unused until step 1 writes a `problem.ex` per row. Nothing
shows what the dataset actually contains today. A person cannot see
it without writing code to open a parquet shard.

## Decision

Wrap every dataset image as a flat billboard card, per the technique
this session already verified: a textured quad, alpha cutout, no
mesh generation needed. Compose every card into one USD stage, each
holding its image and caption as metadata. Serve that stage from
`usd_viewer_app/`, the companion app already built this session.

Scale honestly against the clock. One shard, of 42, proves the
mechanism first: extract, downscale, author, package, verify it
opens, verify it renders. Every later shard runs the same script.
See `DETAILS.md` for the exact scope shipped today, the file-size
reasoning, and what running the remaining 41 shards needs.

## Related

RFD 0064 gives the dataset this RFD displays. RFD 0053 makes USD the
internal format, and this RFD is the deliberate, scoped exception:
a preview stage, in a companion app, not the main studio client.
RFD 0062 gives the Fly.io toplevel this RFD's app deploys beside.
