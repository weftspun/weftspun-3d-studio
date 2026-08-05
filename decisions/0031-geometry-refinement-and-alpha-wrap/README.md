# RFD 0031: Geometry refinement and alpha wrap

**State:** discussion
**Feature:** mesh geometry

## Problem

trellis2cpp (rms80/trellis2cpp) is an MIT C++/ggml port of the
TRELLIS.2 stage-1 geometry pipeline. The richiejp pbr-textures fork
adds geometry refinement and PBR textures under the same license. It
runs on GPU backends through ggml, and it exports textured GLB
without CUDA.

The fork adds CGAL as an optional build dependency. CGAL uses the GPL
license, and RFD 0028 excludes GPL on license grounds.

## Decision

Do not make CGAL a required dependency. Keep it optional, or drop the
alpha wrap step from the build. The fork still produces GLBs without
CGAL.

See `DETAILS.md` for what the alpha wrap does, the permissive
replacement options, and the blocklisted wrap tools.

## Related

RFD 0028 records the license gate. The alpha wrap step stays
optional, or absent, until a real need justifies a rebuild.
