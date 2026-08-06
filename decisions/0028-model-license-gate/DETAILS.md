# RFD 0028 details: deleted and blocklisted models

## Deleted models

PartField, PartPacker, and FastMesh fail the gate. Their weight
licenses permit non-commercial use only.

- PartField uses the NVIDIA license section 3.3.
- PartPacker uses the NVIDIA Source Code License section 3.3.
- FastMesh uses the S-Lab non-commercial license.

The pass tracks in issue #6. These models are not in the catalog. The
repository does not reference them in the UI. Their residual
references remain in docs/api/api.md. The delete pass removes them.

## Blocklisted models

- hunyuan3dv21_image_to_raw_mesh uses the Tencent Community license.
  The license has territory and MAU rules. The blocklist removes it.
- ultrashape_image_to_raw_mesh inherits the Hunyuan pipelines. It
  inherits the Tencent rules. Review it with the same gate.
- hunyuan3dv21_image_to_textured_mesh uses the same Tencent license.
  It needs the same review.
- hunyuan3dv21_image_mesh_painting uses the same Tencent license. It
  needs the same review.
- CGAL uses the GPL license with a commercial dual license. The
  project excludes GPL on license grounds. The blocklist removes it.

The FOSS replacement for raw mesh generation is TRELLIS.2. It uses the
MIT license. The catalog already carries it.
