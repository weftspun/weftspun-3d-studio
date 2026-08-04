"""Pixal3D image to textured mesh, PBR. RFD 0040.

This is the primary image to 3D path. TRELLIS.2 in RFD 0038 is the
alternative, and it writes no PBR maps.

A PBR result is a GLB plus its map set, thus predict() returns a
BaseModel and not a Path.

The parameter count is not measured yet. RFD 0040 gives the command,
and RFD 0027 cannot close its budget until that number exists.
"""

from cog import BasePredictor, BaseModel, Input, Path

MAX_MESH_VERTICES = 210000


class Output(BaseModel):
    """RFD 0053. The layer is the working file, and the GLB ships.

    A PBR material survives the round trip through USD. It does not
    survive a hand-rolled map set, thus the layer is the record and
    the loose maps are a convenience.
    """

    layer: Path
    glb: Path
    base_color: Path
    metallic_roughness: Path
    normal: Path


class Predictor(BasePredictor):
    def setup(self) -> None:
        raise NotImplementedError("Blocked. See RFD 0040.")

    def predict(
        self,
        image: Path = Input(description="One image of the subject."),
        texture_resolution: int = Input(
            description="Edge length of each map, in pixels.",
            choices=[512, 1024, 2048],
            default=1024,
        ),
        decimation_target: int = Input(
            description="Face budget. The API caps the mesh here.",
            ge=1000,
            le=MAX_MESH_VERTICES,
            default=MAX_MESH_VERTICES,
        ),
        seed: int = Input(description="Random seed. -1 picks one.", default=-1),
    ) -> Output:
        raise NotImplementedError("Blocked. See RFD 0040.")
