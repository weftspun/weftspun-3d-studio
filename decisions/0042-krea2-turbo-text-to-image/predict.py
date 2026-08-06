"""Krea 2 Turbo text to image. RFD 0042.

Four models live in one folder: a 12.0 B backbone, a 4.7 B T5, a
0.12 B CLIP, and a 0.08 B VAE.

The loads stage. The text encoders run and unload before the backbone
loads, because the backbone never reads the encoders again. That keeps
the peak near the backbone size, and not near the sum.

RFD 0036 says setup() loads the weights and predict() loads nothing.
This Cog bends that rule on purpose, and the staging is the reason.
setup() maps every file, and predict() moves parts to the device.
"""

from cog import BasePredictor, Input, Path

# Turbo. More steps cost time and give no better image.
DEFAULT_STEPS = 4


class Predictor(BasePredictor):
    def setup(self) -> None:
        import torch

        self.device = "cuda"
        # Map, do not move. The move happens per stage in predict().
        self.files = {
            "backbone": "/weights/backbone.gguf",
            "t5": "/weights/t5.gguf",
            "clip": "/weights/clip.gguf",
            "vae": "/weights/vae.gguf",
        }
        self.torch = torch

    def predict(
        self,
        prompt: str = Input(description="What to draw."),
        negative_prompt: str = Input(description="What to avoid.", default=""),
        width: int = Input(description="Width in pixels.", ge=256, le=2048, default=1024),
        height: int = Input(description="Height in pixels.", ge=256, le=2048, default=1024),
        steps: int = Input(
            description="Denoise steps. This is the Turbo variant.",
            ge=1,
            le=12,
            default=DEFAULT_STEPS,
        ),
        seed: int = Input(description="Random seed. -1 picks one.", default=-1),
    ) -> Path:
        # Stage 1: encode, then free. Stage 2: denoise. Stage 3: decode.
        raise NotImplementedError("Port the staged Krea 2 Turbo pipeline here.")
