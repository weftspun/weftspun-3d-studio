defmodule WeftspunStudio.Inventory do
  @moduledoc """
  The model inventory recorded in RFD 0016.

  Phase 1 of RFD 0019 mirrors this data and checks it against the
  JavaScript catalog. `src/library/aiModelsCatalog.js` stays
  authoritative until phase 2 turns the direction around.

  Keep this list and the RFD 0016 tables in step. A change to one
  without the other makes `WeftspunStudio.JsCatalog.diff/1` noisy.
  """

  alias WeftspunStudio.Model

  defp m(id, type, task, runs_on, group, status, note \\ nil) do
    %Model{
      id: id,
      type: type,
      task: task,
      runs_on: runs_on,
      group: group,
      status: status,
      note: note
    }
  end

  @doc "Every model in the inventory, including legacy and vetoed entries."
  @spec all() :: [Model.t()]
  def all, do: core() ++ environment() ++ splat() ++ legacy() ++ see_through_components()

  @doc "Models available for new work."
  @spec active() :: [Model.t()]
  def active, do: Enum.filter(all(), &Model.active?/1)

  @doc "Models a licence gate or a review removed."
  @spec vetoed() :: [Model.t()]
  def vetoed, do: Enum.filter(all(), &Model.vetoed?/1)

  @doc "Look a model up by its id."
  @spec fetch(String.t()) :: {:ok, Model.t()} | :error
  def fetch(id) do
    case Enum.find(all(), &(&1.id == id)) do
      nil -> :error
      model -> {:ok, model}
    end
  end

  @doc "Every model id, sorted."
  @spec ids() :: [String.t()]
  def ids, do: all() |> Enum.map(& &1.id) |> Enum.sort()

  @doc "Models grouped by their `:group` field."
  @spec by_group() :: %{Model.group() => [Model.t()]}
  def by_group, do: Enum.group_by(all(), & &1.group)

  @spec core() :: [Model.t()]
  def core do
    [
      m(
        "trellis2_image_to_textured_mesh",
        :deep_learning,
        "Image to 3D",
        :dgx_api,
        :core,
        :active
      ),
      m(
        "trellis2_image_mesh_painting",
        :deep_learning,
        "Image mesh painting",
        :dgx_api,
        :core,
        :active
      ),
      m(
        "pixal3d_image_to_textured_mesh",
        :deep_learning,
        "Image to 3D (PBR)",
        :dgx_api,
        :core,
        :active
      ),
      m("p3sam_mesh_segmentation", :deep_learning, "Mesh segmentation", :dgx_api, :core, :active),
      m("krea2_turbo_text_to_image", :deep_learning, "Text to image", :dgx_api, :core, :active),
      m("qwen_q4_k_m_image_edit", :deep_learning, "Image editing", :dgx_api, :core, :active),
      m(
        "seethrough_layer_decomposition",
        :deep_learning,
        "Image to layers",
        :dgx_api,
        :core,
        :active,
        "Cog model on the DGX API. see-through.cpp runs the same models locally."
      ),
      m("kimodo_text_to_motion", :deep_learning, "Text to motion", :dgx_api, :core, :active),
      m("skintokens_auto_rig", :deep_learning, "Auto rig (full)", :dgx_api, :core, :active),
      m("instant_meshes_retopology", :geometric, "Mesh retopology", :dgx_api, :core, :active),
      m("xatlas_uv_unwrapping", :geometric, "UV unwrapping", :dgx_api, :core, :active),
      m(
        "voxhammer_text_mesh_editing",
        :deep_learning,
        "Text mesh editing",
        :dgx_api,
        :core,
        :active
      ),
      m(
        "voxhammer_image_mesh_editing",
        :deep_learning,
        "Image mesh editing",
        :dgx_api,
        :core,
        :active
      )
    ]
  end

  @spec environment() :: [Model.t()]
  def environment do
    [
      m(
        "weftspun_image_to_world",
        :deep_learning,
        "Image to world",
        :dgx_api,
        :environment,
        :active
      ),
      m(
        "lingbot_map_environment_scan",
        :deep_learning,
        "Environment scan",
        :dgx_api,
        :environment,
        :active
      )
    ]
  end

  @spec splat() :: [Model.t()]
  def splat do
    [
      m("worldmirror2_reconstruct", :deep_learning, "Photos to splat", :dgx_api, :splat, :active),
      m("triposplat_image_to_splat", :deep_learning, "Image to splat", :dgx_api, :splat, :active),
      m("colmap_3dgs_reconstruct", :geometric, "Photos to splat", :dgx_api, :splat, :active)
    ]
  end

  @spec legacy() :: [Model.t()]
  def legacy do
    [
      m(
        "trellis_text_to_textured_mesh",
        :deep_learning,
        "Text to 3D",
        :dgx_api,
        :legacy,
        :legacy
      ),
      m(
        "trellis_image_to_textured_mesh",
        :deep_learning,
        "Image to 3D (legacy)",
        :dgx_api,
        :legacy,
        :legacy
      ),
      m(
        "trellis_image_mesh_painting",
        :deep_learning,
        "Image mesh painting (legacy)",
        :dgx_api,
        :legacy,
        :legacy
      ),
      m(
        "trellis_text_mesh_painting",
        :deep_learning,
        "Text mesh painting",
        :dgx_api,
        :legacy,
        :legacy
      ),
      m(
        "hunyuan3dv21_image_to_textured_mesh",
        :deep_learning,
        "Image to 3D",
        :dgx_api,
        :legacy,
        :vetoed,
        "Tencent Community licence. Territory and MAU rules."
      ),
      m(
        "hunyuan3dv21_image_to_raw_mesh",
        :deep_learning,
        "Image to raw mesh",
        :dgx_api,
        :legacy,
        :vetoed,
        "Tencent Community licence. Territory and MAU rules."
      ),
      m(
        "hunyuan3dv21_image_mesh_painting",
        :deep_learning,
        "Image mesh painting",
        :dgx_api,
        :legacy,
        :vetoed,
        "Tencent Community licence. Territory and MAU rules."
      ),
      m(
        "ultrashape_image_to_raw_mesh",
        :deep_learning,
        "Image to raw mesh",
        :dgx_api,
        :legacy,
        :vetoed,
        "Inherits the Hunyuan pipelines and the Tencent rules."
      ),
      m("unirig_auto_rig", :deep_learning, "Auto rig (template VRM)", :dgx_api, :legacy, :vetoed),
      m(
        "appearance_component_auto_rig",
        :deep_learning,
        "Auto rig (appearance)",
        :dgx_api,
        :legacy,
        :vetoed
      ),
      m(
        "creature_template_auto_rig",
        :deep_learning,
        "Auto rig (creature)",
        :dgx_api,
        :legacy,
        :vetoed
      )
    ]
  end

  @doc """
  Components of `seethrough_layer_decomposition`.

  see-through.cpp runs these locally with ggml on a Vulkan backend.
  The task entry names one model, but the pipeline runs a LaMa
  inpainter, an SDXL layer diffusion stack, and a Marigold depth
  stack.
  """
  @spec see_through_components() :: [Model.t()]
  def see_through_components do
    [
      m(
        "seethrough.lama",
        :deep_learning,
        "Inpaint hidden area",
        :local,
        :component,
        :active,
        "LaMa"
      ),
      m(
        "seethrough.layerdiff_unet",
        :deep_learning,
        "Generate layers",
        :local,
        :component,
        :active,
        "SDXL UNet"
      ),
      m(
        "seethrough.layerdiff_te1",
        :deep_learning,
        "Prompt encode",
        :local,
        :component,
        :active,
        "CLIP text encoder"
      ),
      m(
        "seethrough.layerdiff_te2",
        :deep_learning,
        "Prompt encode",
        :local,
        :component,
        :active,
        "CLIP text encoder 2"
      ),
      m(
        "seethrough.layerdiff_vae",
        :deep_learning,
        "Latent decode",
        :local,
        :component,
        :active,
        "SDXL VAE"
      ),
      m(
        "seethrough.trans_vae",
        :deep_learning,
        "Alpha decode",
        :local,
        :component,
        :active,
        "TransparentVAE"
      ),
      m(
        "seethrough.marigold_unet",
        :deep_learning,
        "Depth estimate",
        :local,
        :component,
        :active,
        "Marigold"
      ),
      m(
        "seethrough.marigold_te",
        :deep_learning,
        "Depth conditioning",
        :local,
        :component,
        :active,
        "CLIP text encoder"
      ),
      m(
        "seethrough.marigold_vae",
        :deep_learning,
        "Depth decode",
        :local,
        :component,
        :active,
        "Marigold VAE"
      )
    ]
  end
end
