"""LingBot-Map environment scan. RFD 0050.

Two phases. Phase A tracks the camera, and Phase B reconstructs the
surfaces from those poses.

The scale is the product. A twin that is 3 percent small is not a
twin, thus a_write_stage requires the metric gate and a failed scan
produces nothing.

The orientation rule comes from decisions/agent/DECISIONS.md, dated
2026-07-26. Never the TripoSplat X-flip, and never the XYZRGB point
stride: that stride scatters a Gaussian PLY.
"""

from pathlib import Path as FsPath

from cog import BasePredictor, BaseModel, Input, Path

DOMAIN = FsPath(__file__).with_name("domain.ex")
PROBLEM = FsPath(__file__).with_name("problem.ex")

# The one legal value. See the module note.
ORIENTATION_MODE = "none"


class ScaleGateError(ValueError):
    """The door measurement disagrees with the known width."""


class Output(BaseModel):
    stage: Path
    point_cloud: Path
    door_width_metres: float
    scale_error_percent: float


class Predictor(BasePredictor):
    def setup(self) -> None:
        raise NotImplementedError("Blocked. See RFD 0050.")

    def predict(
        self,
        video: Path = Input(description="An outward-camera walk through the room."),
        known_door_width_metres: float = Input(
            description="The real width of a door in the scan. This sets the scale.",
            ge=0.5,
            le=2.0,
            default=0.82,
        ),
        tolerance_percent: float = Input(
            description="How far the measured width may differ before the scan fails.",
            ge=0.1,
            le=10.0,
            default=2.0,
        ),
        seed: int = Input(description="Random seed. -1 picks one.", default=-1),
    ) -> Output:
        raise NotImplementedError("Blocked. See RFD 0050.")
