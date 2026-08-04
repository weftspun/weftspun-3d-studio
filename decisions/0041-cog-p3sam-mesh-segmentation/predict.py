"""P3-SAM mesh segmentation. RFD 0041.

The label array leads, and the split meshes follow. A label is stable
input for the rig stage and the remix stage. A split mesh is not,
because a later decimation renumbers the faces.

The label array is one integer per face. On a mesh at the 210000
vertex cap that array is large, thus it goes out as a JSON file and
not as an inline list.
"""

import json

from cog import BasePredictor, BaseModel, Input, Path


class Output(BaseModel):
    """RFD 0053. The layer holds one scope per part.

    A USD scope names a part without splitting the mesh. The split
    GLBs stay for callers that want files, and the layer stays for
    callers that want the structure.
    """

    layer: Path
    labels: Path
    part_count: int
    parts: list[Path]


class Predictor(BasePredictor):
    def setup(self) -> None:
        from safetensors.torch import load_file

        self.device = "cuda"
        self.model = load_file("/weights/p3sam.safetensors", device=self.device)

    def predict(
        self,
        mesh: Path = Input(description="The mesh to segment. GLB or OBJ."),
        segment_every_part: bool = Input(
            description="Return every part found, and ignore max_parts.",
            default=False,
        ),
        max_parts: int = Input(
            description="Upper bound on the part count.",
            ge=2,
            le=256,
            default=32,
        ),
        seed: int = Input(description="Random seed. -1 picks one.", default=-1),
    ) -> Output:
        raise NotImplementedError("Port the P3-SAM forward pass here.")

    def _write_labels(self, labels: list[int]) -> Path:
        out = Path("/tmp/labels.json")
        out.write_text(json.dumps({"face_labels": labels}))
        return out
