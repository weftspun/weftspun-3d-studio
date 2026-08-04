# RFD 0031: Geometry refinement and alpha wrap

**State:** discussion
**Feature:** mesh geometry

## Problem

trellis2cpp (rms80/trellis2cpp) is an MIT C++/ggml port of the
TRELLIS.2 stage-1 geometry pipeline. The richiejp pbr-textures fork
adds geometry refinement and PBR textures under the same license. It
runs on GPU backends through ggml, and it exports textured GLB without
CUDA.

The fork adds CGAL as an optional build dependency. CGAL uses the GPL
license, and RFD 0028 excludes GPL on license grounds.

## Decision

Do not make CGAL a required dependency. Keep it optional, or drop the
alpha wrap step from the build. The fork still produces GLBs without
CGAL.

## What the alpha wrap does

The fork uses CGAL for alpha wrapping. Alpha wrapping turns a
defective triangle soup into a watertight mesh. The Polygon Mesh
Processing Library and Geogram do not implement it.

## Permissive options

- fTetWild (wildmeshing/fTetWild, MPL-2.0) turns a triangle soup into
  a tetrahedral mesh with a watertight boundary. It is heavier and
  volumetric. It is the preferred replacement.
- Manifold (elalish/manifold, Apache-2.0) repairs a triangle soup into
  a guaranteed manifold surface. It fits the embedded library design,
  and it is the lighter option.
- FOSSIL (szaghi/FOSSIL) implements an alpha wrap API, and it sells a
  BSD or MIT license for commercial use. The code is Fortran 2003+,
  and the wrap is a single-pass octree MVP. It does not fit the C++
  embedded library design.

## Blocklisted wrap tools

- ManifoldPlus (hjwdzh/ManifoldPlus) is non-commercial use only.
- wrapwrap (ipadjen/wrapwrap) uses the AGPL-3 license.
- The 2026 shrink-wrap meshing paper (Scientific Reports) releases no
  code, thus it is not an option.

## Related

RFD 0028 records the license gate. RFD 0032 records the rebuild path.
