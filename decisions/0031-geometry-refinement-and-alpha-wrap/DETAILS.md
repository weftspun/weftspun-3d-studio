# RFD 0031 details: the alpha wrap, permissive options, blocklist

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
