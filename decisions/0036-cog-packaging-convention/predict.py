"""Template Predictor. RFD 0036 records the rules this file follows.

Two rules matter most. setup() loads the weights once, and predict()
loads nothing. predict() takes typed Input fields, and it returns a
Path or a BaseModel, so the schema is machine readable.
"""

from cog import BasePredictor, Input, Path


class Predictor(BasePredictor):
    def setup(self) -> None:
        """Load the weights. This runs once per container."""
        import torch

        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        # Load from the path cog.yaml wrote at build time. Do not
        # reach the network here.
        self.model = None

    def predict(
        self,
        image: Path = Input(description="The input image."),
        seed: int = Input(
            description="Random seed. -1 picks one.",
            default=-1,
        ),
        output_format: str = Input(
            description="The container for the result.",
            choices=["glb", "ply"],
            default="glb",
        ),
    ) -> Path:
        """Run the model. Load no weights here."""
        raise NotImplementedError("Copy this file, and write the body.")
