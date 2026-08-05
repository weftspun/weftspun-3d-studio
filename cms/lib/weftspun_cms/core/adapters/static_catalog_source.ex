# SPDX-License-Identifier: MIT

defmodule WeftspunCMS.Core.Adapters.StaticCatalogSource do
  @moduledoc """
  The catalog that ships with the release.

  It needs no API, thus a headless deployment answers catalog questions
  with no network. An HTTP adapter may replace it later, and the port
  keeps the two answering alike.

  The numbers come from RFD 0026. Two models carry no parameter count,
  and they stay `nil` here. RFD 0040 records why a guess would be
  worse than the gap.
  """

  @behaviour WeftspunCMS.Core.Ports.CatalogSource

  alias WeftspunCMS.Core.Domain.Model

  @models [
    %Model{
      id: "pixal3d_image_to_textured_mesh",
      feature: "image_to_textured_mesh",
      label: "Pixal3D Image to Textured Mesh",
      license: "unknown",
      parameters_billions: nil
    },
    %Model{
      id: "trellis2_image_to_textured_mesh",
      feature: "image_to_textured_mesh",
      label: "TRELLIS.2 Image to Textured Mesh",
      license: "MIT",
      parameters_billions: 4.0
    },
    %Model{
      id: "skintokens_auto_rig",
      feature: "auto_rig",
      label: "SkinTokens Auto Rig",
      parameters_billions: 0.5
    },
    %Model{
      id: "p3sam_mesh_segmentation",
      feature: "mesh_segmentation",
      label: "P3-SAM Mesh Segmentation",
      license: "MIT",
      parameters_billions: 0.4
    },
    %Model{
      id: "krea2_turbo_text_to_image",
      feature: "text_to_image",
      label: "Krea 2 Turbo",
      parameters_billions: 16.9,
      format: :q4_k_m
    },
    %Model{
      id: "qwen_q4_k_m_image_edit",
      feature: "image_editing",
      label: "Qwen Image Edit",
      license: "Apache-2.0",
      parameters_billions: 27.0,
      format: :q4_k_m
    },
    %Model{
      id: "seethrough_layer_decomposition",
      feature: "image_to_layers",
      label: "See-Through Layer Decomposition",
      license: "Apache-2.0",
      parameters_billions: 4.9,
      composite: true
    }
  ]

  @impl true
  def list_models, do: {:ok, @models}

  @impl true
  def list_models_for_feature(feature) do
    {:ok, Enum.filter(@models, &(&1.feature == feature))}
  end

  @impl true
  def fetch_model(id) do
    case Enum.find(@models, &(&1.id == id)) do
      nil -> {:error, :not_found}
      model -> {:ok, model}
    end
  end
end
