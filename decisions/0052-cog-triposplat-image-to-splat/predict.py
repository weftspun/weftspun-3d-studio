"""TripoSplat image to splat. RFD 0052.

The single-photo path. RFD 0051 handles 2 or more photos, and RFD 0049
mounts these same weights to build a world.

Two rules from decisions/agent/DECISIONS.md, dated 2026-07-26.

The X-flip happens here, and the output is already flipped. A caller
must never decide, because a TripoSplat cloud and a LingBot cloud then
look alike and the wrong one takes the flip.

The PLY carries the Gaussian attributes, and not a bare point list.
The viewport loads it through Spark, and the XYZRGB point stride
scatters a Gaussian PLY.
"""

from cog import BasePredictor, BaseModel, Input, Path

# Applied here, never by the caller. See the module note.
APPLY_X_FLIP = True


class Output(BaseModel):
    stage: Path
    splat: Path
    splat_count: int


class Predictor(BasePredictor):
    def setup(self) -> None:
        from safetensors.torch import load_file

        self.device = "cuda"
        self.model = load_file("/weights/triposplat.safetensors", device=self.device)

    def predict(
        self,
        image: Path = Input(description="One photo of the subject."),
        max_splats: int = Input(
            description="Upper bound on the Gaussian count.",
            ge=10000,
            le=2000000,
            default=500000,
        ),
        seed: int = Input(description="Random seed. -1 picks one.", default=-1),
    ) -> Output:
        raise NotImplementedError("Port the TripoSplat forward pass here.")

    def _write_ply(self, gaussians, path: Path) -> None:
        """Write the Gaussian attributes.

        A bare XYZRGB point list would load in the viewport and look
        wrong. Write position, scale, rotation, opacity, and the
        spherical harmonic coefficients.
        """
        raise NotImplementedError
