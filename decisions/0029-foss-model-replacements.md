# RFD 0029: FOSS model replacements

**State:** published
**Feature:** model licensing

## Problem

RFD 0028 removes three models from the catalog. Their tasks still
need a model.

## Decision

Replace each deleted model with a permissive alternative. Prefer the
MIT license and the BSD license.

## PartField replacement (mesh segmentation)

The web search from August 2026 found three MIT candidates.

- PartSAM (czvvd/PartSAM, ICLR 2026) segments parts on native 3D data.
  It supports a segment-every-part mode.
- HoloPart (VAST-AI/Research) completes occluded parts.
- OmniPart (HKU-MMLab, SIGGRAPH Asia 2025) does part-aware 3D
  generation.

PartSAM is the primary recommendation. It trains on native 3D data, so
it works on AI-generated meshes. PartField needs clean mesh
connectivity, which generated meshes lack.

## FastMesh replacement (retopology)

The catalog already carries Instant Meshes under the BSD-3 license. It
is the primary replacement. QuadriFlow, meshoptimizer,
trimesh_decimate, and AutoRemesher are the MIT alternatives.

The QuadWild Bi-MDF fork does not qualify. It uses the GPL-3 license.

## PartPacker replacement (image to raw mesh)

The catalog already carries TRELLIS.2 and TRELLIS. Both use the MIT
license. Prefer them over PartPacker.

## Related

RFD 0028 records the license gate. RFD 0031 records the geometry
refinement path and its alpha wrap problem.
