"""VoxHammer image mesh editing. RFD 0048.

The image variant of RFD 0047. Every stage is shared, and only the
conditioning differs.

The domain lives in the RFD 0047 folder, because two copies would
drift and a drifted guard is a moved vertex. problem.ex here sets
mode.conditioning to "image", and apply_edit takes that alternative.
"""

from pathlib import Path as FsPath

from cog import BasePredictor, BaseModel, Input, Path

DOMAIN = FsPath(__file__).parents[1] / "0047-voxhammer-text-mesh-editing" / "domain.ex"
PROBLEM = FsPath(__file__).with_name("problem.ex")

CONDITIONING = "image"


class Output(BaseModel):
    layer: Path
    glb: Path


class Predictor(BasePredictor):
    def setup(self) -> None:
        from safetensors.torch import load_file

        self.device = "cuda"
        self.sparse_structure = load_file(
            "/weights/sparse_structure.safetensors", device=self.device
        )
        self.slat = load_file("/weights/slat_flow.safetensors", device=self.device)

        self.domain = DOMAIN.read_text()
        self.problem = PROBLEM.read_text()

    def predict(
        self,
        mesh: Path = Input(description="The mesh to edit. USD or GLB."),
        reference: Path = Input(
            description="An image of what the region should become. Not a texture.",
        ),
        region: Path = Input(description="The mask that bounds the edit."),
        seed: int = Input(description="Random seed. -1 picks one.", default=-1),
    ) -> Output:
        raise NotImplementedError("Run the plan, then wire the action bodies.")
