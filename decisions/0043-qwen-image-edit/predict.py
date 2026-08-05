"""Qwen image edit, Q4_K_M. RFD 0043.

27.0 B parameters. In bf16 that is 54.0 GB, which is 46 percent of the
whole catalog. This Cog ships Q4_K_M at 14.85 GB, and RFD 0043 records
why no bf16 build exists.

The instruction is a sentence, and not a tag list. A vision language
encoder reads it, thus "Make the jacket red" works and "jacket, red"
does not.
"""

from cog import BasePredictor, Input, Path


class Predictor(BasePredictor):
    def setup(self) -> None:
        import torch

        self.device = "cuda"
        self.torch = torch
        self.edit_path = "/weights/edit.gguf"
        self.vl_path = "/weights/vl.gguf"

    def predict(
        self,
        image: Path = Input(description="The image to edit."),
        instruction: str = Input(
            description="What to change, as a sentence. Not a tag list.",
        ),
        strength: float = Input(
            description="How far from the original to move.",
            ge=0.0,
            le=1.0,
            default=0.8,
        ),
        steps: int = Input(description="Denoise steps.", ge=1, le=50, default=20),
        seed: int = Input(description="Random seed. -1 picks one.", default=-1),
    ) -> Path:
        raise NotImplementedError("Port the Qwen edit loop here, reading GGUF.")
