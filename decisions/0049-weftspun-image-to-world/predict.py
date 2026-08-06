"""Weftspun image to world. RFD 0049.

Two models, no weights of its own. TripoSplat builds the environment,
and TRELLIS.2 builds the props.

The result is a USD stage. The splat is one layer, and each prop is a
reference under its own prim. A splat and a mesh are different things,
thus one flat file would serve neither. RFD 0053 gives the rule.

prop_count of 0 is the common case. build_props then takes its :none
alternative, and the plan never mentions TRELLIS.2.
"""

from pathlib import Path as FsPath

from cog import BasePredictor, BaseModel, Input, Path

DOMAIN = FsPath(__file__).with_name("domain.ex")
PROBLEM = FsPath(__file__).with_name("problem.ex")


class Output(BaseModel):
    stage: Path
    environment: Path
    props: list[Path]


class Predictor(BasePredictor):
    def setup(self) -> None:
        import torch

        self.device = "cuda"
        self.torch = torch

        # Paths only. a_load moves one half to the device, and
        # a_unload frees it. The peak is then 8.0 GB, and not 10.2 GB.
        self.weights = {
            "triposplat": "/weights/triposplat.safetensors",
            "trellis2": "/weights/slat_flow.safetensors",
        }
        self.resident = {}

        self.domain = DOMAIN.read_text()
        self.problem = PROBLEM.read_text()

        self.actions = {
            "a_load": self._load,
            "a_unload": self._unload,
            "a_make_splat": self._make_splat,
            "a_make_props": self._make_props,
            "a_compose_stage": self._compose_stage,
        }

    def predict(
        self,
        image: Path = Input(description="One image of the scene."),
        prop_count: int = Input(
            description="How many props to generate. 0 gives the environment only.",
            ge=0,
            le=16,
            default=0,
        ),
        prop_prompts: str = Input(
            description="One prompt per prop, separated by newlines.",
            default="",
        ),
        seed: int = Input(description="Random seed. -1 picks one.", default=-1),
    ) -> Output:
        raise NotImplementedError("Run the plan, then wire the action bodies.")

    def _load(self, component: str) -> None:
        from safetensors.torch import load_file

        self.resident[component] = load_file(self.weights[component], device=self.device)

    def _unload(self, component: str) -> None:
        self.resident.pop(component, None)
        self.torch.cuda.empty_cache()

    def _make_splat(self) -> None:
        raise NotImplementedError

    def _make_props(self) -> None:
        raise NotImplementedError

    def _compose_stage(self) -> None:
        """Author the stage. The splat sublayers, and each prop
        references under its own prim."""
        raise NotImplementedError
