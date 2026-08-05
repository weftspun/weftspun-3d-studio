"""TRELLIS.2 image to textured mesh. RFD 0038.

Two flows run in order. The sparse structure flow makes the coarse
occupancy, and the SLat flow makes the detail and the texture. Both
read the same DINOv2 image embedding, thus setup() loads the encoder
once and predict() reuses it.
"""

from cog import BasePredictor, BaseModel, Input, Path

# src/library/aiModelsCatalog.js API_MAX_MESH_VERTICES. A mesh above
# this fails the API upload, thus it fails every later stage.
MAX_MESH_VERTICES = 210000


class Output(BaseModel):
    """RFD 0053. The layer is the working file, and the GLB ships."""

    layer: Path
    glb: Path


class Predictor(BasePredictor):
    def setup(self) -> None:
        import torch

        self.device = "cuda"
        self.dtype = torch.bfloat16
        self.encoder = self._load("/weights/dinov2_vitl14.safetensors")
        self.sparse_structure = self._load("/weights/sparse_structure.safetensors")
        self.slat = self._load("/weights/slat_flow.safetensors")

    def _load(self, path: str):
        from safetensors.torch import load_file

        return load_file(path, device=self.device)

    def predict(
        self,
        image: Path = Input(description="One image of the subject."),
        texture_resolution: int = Input(
            description="Edge length of the texture, in pixels.",
            choices=[512, 1024, 2048],
            default=1024,
        ),
        decimation_target: int = Input(
            description=(
                "Face budget. The API rejects a mesh above "
                f"{MAX_MESH_VERTICES} vertices."
            ),
            ge=1000,
            le=MAX_MESH_VERTICES,
            default=MAX_MESH_VERTICES,
        ),
        seed: int = Input(description="Random seed. -1 picks one.", default=-1),
    ) -> Output:
        # This model authors the base layer. Every later stage adds a
        # sublayer over it, and none of them rewrite this one.
        raise NotImplementedError("Port the TRELLIS.2 stage-1 and stage-2 loop here.")
