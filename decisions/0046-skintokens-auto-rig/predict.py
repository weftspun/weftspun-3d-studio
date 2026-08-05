"""SkinTokens auto rig. RFD 0046.

The rig is an opinion about a mesh that already exists, thus it goes
into its own USD layer over the mesh layer. RFD 0053 gives that rule.

A GLB skin binds to one mesh. When retopology later changes the mesh,
that skin breaks. A UsdSkel binding in its own layer survives a new
mesh layer below it, and only the weights need a rebind.
"""

from cog import BasePredictor, BaseModel, Input, Path

# SkinTokens rejects template mode. RFD 0035 records that UniRig is
# the only backend for it.
RIG_MODES = ["skeleton", "skin", "full"]


class Output(BaseModel):
    layer: Path
    vrm: Path
    joint_count: int


class Predictor(BasePredictor):
    def setup(self) -> None:
        from safetensors.torch import load_file

        self.device = "cuda"
        self.model = load_file("/weights/skintokens.safetensors", device=self.device)

    def predict(
        self,
        mesh: Path = Input(description="The mesh to rig. GLB or USD."),
        rig_mode: str = Input(
            description="What to produce.",
            choices=RIG_MODES,
            default="full",
        ),
        seed: int = Input(description="Random seed. -1 picks one.", default=-1),
    ) -> Output:
        raise NotImplementedError("Port the SkinTokens forward pass here.")

    def _write_joint_map(self, stage, joints: list[str]) -> None:
        """Record the VRM humanoid mapping as layer metadata.

        USD keeps an ordered joint array with no humanoid meaning. VRM
        names its joints. An exporter that infers the mapping from
        joint names fails on any rig that names a joint differently,
        thus the mapping is written here and read later.
        """
        raise NotImplementedError
