"""See-Through layer decomposition. RFD 0044.

Nine networks. RFD 0030 lists them, and domain.ex orders them.

This file holds no pipeline order. It maps each action name in the
domain to one function, and it runs the plan the planner returns. A
pipeline change therefore edits domain.ex, and not this file.

The planner is taskweft. See RFD 0037.
"""

import json
from pathlib import Path as FsPath

from cog import BasePredictor, BaseModel, Input, Path

DOMAIN = FsPath(__file__).with_name("domain.ex")
PROBLEM = FsPath(__file__).with_name("problem.ex")


class Output(BaseModel):
    psd: Path
    depth: Path
    layer_count: int


class Predictor(BasePredictor):
    def setup(self) -> None:
        import torch

        self.device = "cuda"
        self.torch = torch

        # Paths only. a_load moves a component to the device, and
        # a_unload frees it. The plan says when.
        self.weights = {
            "lama": "/weights/big-lama.safetensors",
            "layerdiff_te1": "/weights/layerdiff-te1.safetensors",
            "layerdiff_te2": "/weights/layerdiff-te2.safetensors",
            "layerdiff_unet": "/weights/layerdiff-unet.safetensors",
            "layerdiff_vae": "/weights/layerdiff-vae.safetensors",
            "trans_vae": "/weights/trans-vae.safetensors",
            "marigold_te": "/weights/marigold-te.safetensors",
            "marigold_unet": "/weights/marigold-unet.safetensors",
            "marigold_vae": "/weights/marigold-vae.safetensors",
        }
        self.resident = {}

        self.actions = {
            "a_load": self._load,
            "a_unload": self._unload,
            "a_inpaint": self._inpaint,
            "a_encode_prompt": self._encode_prompt,
            "a_diffuse_layers": self._diffuse_layers,
            "a_decode_rgb": self._decode_rgb,
            "a_decode_alpha": self._decode_alpha,
            "a_depth_encode": self._depth_encode,
            "a_depth_decode": self._depth_decode,
            "a_write_psd": self._write_psd,
        }

        # The domain is Elixir DSL source, and the planner takes it as
        # a string with format "dsl". Do not parse it here.
        self.domain = DOMAIN.read_text()
        self.problem = PROBLEM.read_text()

    def predict(
        self,
        image: Path = Input(description="One image to decompose into layers."),
        prompt: str = Input(description="What the subject is.", default=""),
        seed: int = Input(description="Random seed. -1 picks one.", default=-1),
    ) -> Output:
        plan = self._plan(image)
        for step in plan:
            name, args = step[0], step[1:]
            self.actions[name](*args)
        raise NotImplementedError("Wire the action bodies, then return Output.")

    def _plan(self, image: Path) -> list[list]:
        """Ask taskweft for the step order.

        The `plan` tool takes `domain_dsl` as a string, and `format`
        of "dsl". It runs over MCP at https://taskweft-mcp.fly.dev/mcp,
        or through the taskweft binary offline.

        A build must not depend on the network, thus cache the plan
        beside the domain and replan only when the domain changes.
        """
        raise NotImplementedError("Call taskweft plan, or read the cached plan.")

    def _replan(self, plan: list[list], fail_step: int) -> list[list]:
        """Resume after a failed stage.

        `plan` takes `plan_json` and `fail_step`, and it returns a new
        tail. The work before the failure stands, thus a lost decode
        does not repeat the diffusion. RFD 0037 records that this is
        the reason a composite is a domain.
        """
        raise NotImplementedError("Call taskweft plan with plan_json and fail_step.")

    def _load(self, component: str) -> None:
        from safetensors.torch import load_file

        self.resident[component] = load_file(self.weights[component], device=self.device)

    def _unload(self, component: str) -> None:
        self.resident.pop(component, None)
        self.torch.cuda.empty_cache()

    def _inpaint(self) -> None:
        raise NotImplementedError

    def _encode_prompt(self) -> None:
        raise NotImplementedError

    def _diffuse_layers(self) -> None:
        raise NotImplementedError

    def _decode_rgb(self) -> None:
        raise NotImplementedError

    def _decode_alpha(self) -> None:
        raise NotImplementedError

    def _depth_encode(self) -> None:
        raise NotImplementedError

    def _depth_decode(self) -> None:
        raise NotImplementedError

    def _write_psd(self) -> None:
        raise NotImplementedError
