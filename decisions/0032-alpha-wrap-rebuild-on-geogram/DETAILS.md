# RFD 0032 details: primitives, the work, stage separation

## Geogram provides the primitives

- Delaunay3d builds the 3D Delaunay triangulation with exact
  predicates. It supports the bounding box initialization.
- MeshFacetsAABB answers the distance, projection, and intersection
  queries.
- Expansion arithmetic keeps the combinatorial decisions exact.

## The work

The rebuild work is the traversal loop from the paper. It carves
outside cells and inserts Steiner points. It then extracts the surface
between inside and outside cells. Use PMP for post-process cleanup,
because it decimates and remeshes the wrap. PMP does not provide the
carving structure.

FOSSIL proves the independent implementation. It uses an octree
variant instead of Delaunay. A Geogram-based build follows the paper
directly.

## Stage separation

Remeshing and decimation stay in a separate stage. The Studio pipeline
already separates retopology from mesh generation. trellis2cpp refines
geometry, and it does not replace the retopology stage.
