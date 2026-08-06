"""Kimodo text to motion. RFD 0045.

The model emits SOMA. The client wants VRM humanoid tracks. Those are
two things, thus this Cog returns two things.

A single VRM output would make the model look wrong when the retarget
is what failed. Keeping them apart names the failure correctly.

The validation from RFD 0007 runs here. A motion that leaves the floor
must fail before the viewport loads it.
"""

from cog import BasePredictor, BaseModel, Input, Path


class Output(BaseModel):
    soma: Path
    vrm: Path | None
    valid: bool
    validation_detail: str


class Predictor(BasePredictor):
    def setup(self) -> None:
        from safetensors.torch import load_file

        self.device = "cuda"
        self.model = load_file("/weights/kimodo.safetensors", device=self.device)

    def predict(
        self,
        prompt: str = Input(description="The motion to make, as a sentence."),
        duration_seconds: float = Input(
            description="How long the motion runs.",
            ge=0.5,
            le=30.0,
            default=4.0,
        ),
        fps: int = Input(description="Frames per second.", ge=12, le=120, default=30),
        target_rig: Path = Input(
            description="Optional VRM to retarget onto. Without it, SOMA only.",
            default=None,
        ),
        seed: int = Input(description="Random seed. -1 picks one.", default=-1),
    ) -> Output:
        raise NotImplementedError("Port the Kimodo sampler, then the retarget.")

    def _validate(self, motion) -> tuple[bool, str]:
        """RFD 0007. Check the floor contact and the joint limits."""
        raise NotImplementedError
