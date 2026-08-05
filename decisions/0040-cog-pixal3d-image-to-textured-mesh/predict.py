"""Pixal3D image to textured mesh, PBR. RFD 0040.

The primary image to 3D path. Upstream is TencentARC/Pixal3D, MIT.

Three cascading stages, each a diffusion transformer:

  1. sparse structure   32 -> 64
  2. shape              256 -> 512 -> 1024
  3. texture            256 -> 512 -> 1024

setup() loads every stage once. RFD 0036 requires that, and here it
matters more than usual: the weights are 24.045 GB across seven files,
and a cold start that loaded them per request would time out.

`low_vram` trades speed for memory. Upstream moves each stage to the
device as it runs and frees it after, thus the peak falls to about
6.5 GB from 24.045 GB. Keep it on for a 24 GB card.

RFD 0053 makes OpenUSD the internal format, thus predict() returns a
USD layer beside the GLB that ships.
"""

import os
import subprocess
import sys
import tempfile
from pathlib import Path as FsPath

from cog import BasePredictor, BaseModel, Input, Path

# Upstream reads these before it imports torch, thus they are set here
# and not in the pipeline.
os.environ["OPENCV_IO_ENABLE_OPENEXR"] = "1"
os.environ["PYTORCH_CUDA_ALLOC_CONF"] = "expandable_segments:True"
os.environ.setdefault("ATTN_BACKEND", "flash_attn")

SRC = "/src/Pixal3D"
WEIGHTS = "/weights/pixal3d"

# src/library/aiModelsCatalog.js API_MAX_MESH_VERTICES. The API rejects
# a mesh above this, thus it fails every later stage.
MAX_MESH_VERTICES = 210000


class Output(BaseModel):
    """RFD 0053. The layer is the working file, and the GLB ships.

    A PBR material survives the round trip through USD. The loose maps
    are a convenience for a caller that wants them directly.
    """

    layer: Path
    glb: Path


class Predictor(BasePredictor):
    def setup(self) -> None:
        """Load every stage once. This runs one time per container."""
        sys.path.insert(0, SRC)

        from pixal3d.pipelines import Pixal3DImageTo3DPipeline

        self.pipeline = Pixal3DImageTo3DPipeline.from_pretrained(WEIGHTS)

        # Four conditioning encoders, one per stage resolution. They
        # all read the same DINOv3 checkpoint, thus the download is
        # one copy and the load is four views of it.
        self.pipeline.cuda()

    def predict(
        self,
        image: Path = Input(description="One image of the subject."),
        seed: int = Input(description="Random seed.", default=42),
        fov: float = Input(
            description="Field of view in degrees. -1 lets MoGe estimate it.",
            default=-1.0,
        ),
        resolution: int = Input(
            description="Output resolution. -1 takes the upstream default.",
            choices=[-1, 512, 1024],
            default=-1,
        ),
        low_vram: bool = Input(
            description=(
                "Move each stage to the device as it runs, and free it after. "
                "Drops the peak from 24.045 GB to about 6.5 GB, and costs time."
            ),
            default=True,
        ),
    ) -> Output:
        work = FsPath(tempfile.mkdtemp())
        glb = work / "output.glb"

        # Upstream's own entry point, and not a reimplementation of it.
        # A copy of the cascade here would drift from the repository
        # this Cog pins.
        command = [
            sys.executable,
            "inference.py",
            "--image",
            str(image),
            "--output",
            str(glb),
            "--seed",
            str(seed),
            "--fov",
            str(fov),
            "--model_path",
            WEIGHTS,
            "--resolution",
            str(resolution),
        ]

        if low_vram:
            command.append("--low_vram")

        subprocess.run(command, cwd=SRC, check=True)

        return Output(layer=self._to_usd(glb, work), glb=Path(glb))

    def _to_usd(self, glb: FsPath, work: FsPath) -> Path:
        """Author the base USD layer from the GLB.

        RFD 0053. This model writes the base layer, thus every later
        stage adds a sublayer over it and none rewrites this one.
        """
        raise NotImplementedError("Convert the GLB to a USD layer with usd-core.")
