"""VoxHammer text mesh editing. RFD 0047.

No weights of its own. The TRELLIS.2 backbone from RFD 0038 comes
from the base image.

domain.ex orders the stages. The guard that matters is
preserved_outside: a_decode refuses to run before a_splice, thus no
plan can move a vertex outside the mask.

The result is a USD sublayer over the source mesh. A caller mutes the
layer and gets the original back. RFD 0053 gives that rule.
"""

from pathlib import Path as FsPath

from cog import BasePredictor, BaseModel, Input, Path

DOMAIN = FsPath(__file__).with_name("domain.ex")
PROBLEM = FsPath(__file__).with_name("problem.ex")

CONDITIONING = "text"


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

        # Elixir DSL source. The planner takes it as a string.
        self.domain = DOMAIN.read_text()
        self.problem = PROBLEM.read_text()

        self.actions = {
            "a_mark_region": self._mark_region,
            "a_voxelize": self._voxelize,
            "a_invert": self._invert,
            "a_edit_text": self._edit_text,
            "a_splice": self._splice,
            "a_decode": self._decode,
            "a_write_layer": self._write_layer,
        }

    def predict(
        self,
        mesh: Path = Input(description="The mesh to edit. USD or GLB."),
        instruction: str = Input(description="What to change, as a sentence."),
        region: Path = Input(description="The mask that bounds the edit."),
        seed: int = Input(description="Random seed. -1 picks one.", default=-1),
    ) -> Output:
        raise NotImplementedError("Run the plan, then wire the action bodies.")

    def _mark_region(self) -> None:
        raise NotImplementedError

    def _voxelize(self) -> None:
        raise NotImplementedError

    def _invert(self) -> None:
        raise NotImplementedError

    def _edit_text(self) -> None:
        raise NotImplementedError

    def _splice(self) -> None:
        """Paste the original geometry back outside the mask.

        Inversion is lossy. Without this step the decode moves
        vertices the caller never selected.
        """
        raise NotImplementedError

    def _decode(self) -> None:
        raise NotImplementedError

    def _write_layer(self) -> None:
        raise NotImplementedError
