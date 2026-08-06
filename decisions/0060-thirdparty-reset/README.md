# RFD 0060: A thirdparty/ reset

**State:** committed
**Scope:** the repository root

## Problem

`src/library/` held 139 files and 56,376 lines. It predates RFD
0019's strangler fig and RFD 0023's `src/core/` split. 108 files
outside it still imported from it. RFD 0023's per-file move rule
gave no place to put those 108 files a port did not cover yet.

The repository root carried the same problem at a larger scale.
`weftspun_studio/` sat as a subdirectory of the browser client's
tree, even though RFD 0019 makes it the API server the client is one
consumer of. The end-shape system was the guest. The system it
replaces was the host.

## Decision

Two moves, one after the other. First, `src/library/` to
`thirdparty/library/`, as real files and not a symlink. Second,
`weftspun_studio/` becomes the repository root, and everything that
was at the root moves to `thirdparty/3d_studio/` instead.

Gall's law: a complex system that works grew from a simple system
that worked. Moving the browser client to `thirdparty/` marks it a
dependency, not the workspace.

`DETAILS.md` also gives why this was a real move, and not an import
rewrite, plus every path the move touched and the verified results.

## Related

RFD 0019 gives the strangler fig this reset makes room for. RFD 0023
gives the per-file move rule this RFD does not replace. RFD 0057
tracks two items this move left open. RFD 0058 gives the Quadlet
paths this RFD updates.
