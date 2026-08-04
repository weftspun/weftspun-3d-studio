"""TRELLIS.2 image mesh painting. RFD 0039.

The weights come from the RFD 0038 base image. This file adds the
painting path only.

The mesh must carry a UV set. This Cog does not unwrap, because a
hidden unwrap makes the output depend on a step the caller never
asked for. Run xatlas first when the UV set is absent.
"""

from cog import BasePredictor, BaseModel, Input, Path


class Output(BaseModel):
    """RFD 0053. A material layer over the mesh, plus the GLB."""

    layer: Path
    glb: Path


class MissingUVError(ValueError):
    """The mesh has no UV set, thus the texture has nowhere to land."""


class Predictor(BasePredictor):
    def setup(self) -> None:
        from safetensors.torch import load_file

        self.device = "cuda"
        self.encoder = load_file("/weights/dinov2_vitl14.safetensors", device=self.device)
        self.slat = load_file("/weights/slat_flow.safetensors", device=self.device)

    def predict(
        self,
        mesh: Path = Input(description="The mesh to paint. GLB, with a UV set."),
        image: Path = Input(description="The image the texture comes from."),
        texture_resolution: int = Input(
            description="Edge length of the texture, in pixels.",
            choices=[512, 1024, 2048],
            default=1024,
        ),
        seed: int = Input(description="Random seed. -1 picks one.", default=-1),
    ) -> Output:
        # The layer carries material bindings only. It overrides no
        # geometry, thus a caller may mute it and keep the mesh.
        import trimesh

        loaded = trimesh.load(str(mesh), force="mesh")
        if not hasattr(loaded.visual, "uv") or loaded.visual.uv is None:
            raise MissingUVError("Run xatlas UV unwrapping before this model.")

        raise NotImplementedError("Port the TRELLIS.2 painting pass here.")
