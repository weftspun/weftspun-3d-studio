"""WorldMirror 2.0 photos to splat. RFD 0051.

The multi-photo path. resolveSplatModelForPhotos in
src/library/aiModelsCatalog.js selects this model at 2 or more photos,
and RFD 0052 below that.

The count guard is here as well as in the client. A single photo must
fail with a clear reason, and it must not produce a poor splat that
reads as a model fault.

No pose input. WorldMirror solves the poses inside the forward pass,
which is why it works at 2 photos where COLMAP fails.
"""

from cog import BasePredictor, BaseModel, Input, Path

MIN_PHOTOS = 2


class TooFewPhotosError(ValueError):
    """One photo is the RFD 0052 path, and not this one."""


class Output(BaseModel):
    stage: Path
    splat: Path
    splat_count: int


class Predictor(BasePredictor):
    def setup(self) -> None:
        from safetensors.torch import load_file

        self.device = "cuda"
        self.model = load_file("/weights/worldmirror2.safetensors", device=self.device)

    def predict(
        self,
        images: list[Path] = Input(description="Two or more photos of the subject."),
        max_splats: int = Input(
            description="Upper bound on the Gaussian count.",
            ge=10000,
            le=5000000,
            default=1000000,
        ),
        seed: int = Input(description="Random seed. -1 picks one.", default=-1),
    ) -> Output:
        if len(images) < MIN_PHOTOS:
            raise TooFewPhotosError(
                f"This model needs {MIN_PHOTOS} photos or more. "
                "Use triposplat_image_to_splat for one photo."
            )
        raise NotImplementedError("Port the WorldMirror forward pass here.")
