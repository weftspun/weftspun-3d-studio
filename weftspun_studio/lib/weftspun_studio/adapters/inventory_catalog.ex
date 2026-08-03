# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule WeftspunStudio.Adapters.InventoryCatalog do
  @moduledoc """
  Driven adapter: serves the model catalog from local data.

  This is the smallest part of the client that can move on its own.
  It needs no AI, no network, and no persistence, so it is the first
  piece RFD 0019 takes. Gall's law: a working simple system first.

  The entries mirror `src/library/aiModelsCatalog.js`.
  `WeftspunStudio.JsCatalog` holds the two in step, and the parity
  test fails when they drift.
  """

  @behaviour WeftspunStudio.Ports.CatalogSource

  # Generated from src/library/aiModelsCatalog.js. Phase 1 of RFD 0019
  # serves what the client already reads.
  @entries [
    %{
      value: "trellis_text_to_textured_mesh",
      label: "TRELLIS Text to Textured Mesh",
      feature: "text_to_textured_mesh"
    },
    %{
      value: "trellis_text_mesh_painting",
      label: "TRELLIS Text Mesh Painting",
      feature: "text_mesh_painting"
    },
    %{
      value: "hunyuan3dv21_image_to_raw_mesh",
      label: "Hunyuan3D v2.1 Image to Raw Mesh (recommended)",
      feature: "image_to_raw_mesh"
    },
    %{
      value: "ultrashape_image_to_raw_mesh",
      label: "UltraShape Image to Raw Mesh",
      feature: "image_to_raw_mesh"
    },
    %{
      value: "trellis2_image_to_textured_mesh",
      label: "TRELLIS.2 Image to Textured Mesh (recommended)",
      feature: "image_to_textured_mesh"
    },
    %{
      value: "pixal3d_image_to_textured_mesh",
      label: "Pixal3D Image to Textured Mesh (PBR, high fidelity)",
      feature: "image_to_textured_mesh"
    },
    %{
      value: "hunyuan3dv21_image_to_textured_mesh",
      label: "Hunyuan3D v2.1 Image to Textured Mesh",
      feature: "image_to_textured_mesh"
    },
    %{
      value: "trellis_image_to_textured_mesh",
      label: "TRELLIS v1 Image to Textured Mesh (legacy — avoid on DGX)",
      feature: "image_to_textured_mesh"
    },
    %{
      value: "trellis2_image_mesh_painting",
      label: "TRELLIS.2 Image Mesh Painting (recommended)",
      feature: "image_mesh_painting"
    },
    %{
      value: "hunyuan3dv21_image_mesh_painting",
      label: "Hunyuan3D v2.1 Image Mesh Painting",
      feature: "image_mesh_painting"
    },
    %{
      value: "trellis_image_mesh_painting",
      label: "TRELLIS v1 Image Mesh Painting (legacy)",
      feature: "image_mesh_painting"
    },
    %{
      value: "triposplat_image_to_splat",
      label: "TripoSplat Image to Gaussian Splat (1 photo)",
      feature: "image_to_splat"
    },
    %{
      value: "worldmirror2_reconstruct",
      label: "WorldMirror 2.0 Photos to Splat (2+ photos)",
      feature: "image_to_splat"
    },
    %{
      value: "colmap_3dgs_reconstruct",
      label: "Photos to Splat (COLMAP — 3+ photos)",
      feature: "image_to_splat"
    },
    %{
      value: "weftspun_image_to_world",
      label: "Image to World (TripoSplat env + TRELLIS.2 props)",
      feature: "image_to_world"
    },
    %{
      value: "lingbot_map_environment_scan",
      label: "Environment scan (LingBot-Map walk → 1:1 twin)",
      feature: "environment_scan"
    },
    %{
      value: "p3sam_mesh_segmentation",
      label: "P3-SAM Mesh Segmentation",
      feature: "mesh_segmentation"
    },
    %{
      value: "skintokens_auto_rig",
      label: "SkinTokens Auto Rig (recommended — full rig + GLB)",
      feature: "auto_rig"
    },
    %{
      value: "unirig_auto_rig",
      label: "UniRig Auto Rig (template VRM / FBX skeleton)",
      feature: "auto_rig"
    },
    %{
      value: "appearance_component_auto_rig",
      label: "Appearance Clothing Fit (VRM slot — Joggers, Shirt, Boots…)",
      feature: "auto_rig"
    },
    %{
      value: "creature_template_auto_rig",
      label: "Creature Template Rig (Mesh2Motion fox / quadruped → GLB)",
      feature: "auto_rig"
    },
    %{
      value: "instant_meshes_retopology",
      label: "Instant Meshes Retopology",
      feature: "mesh_retopology"
    },
    %{value: "xatlas_uv_unwrapping", label: "xatlas UV Unwrapping", feature: "uv_unwrapping"},
    %{
      value: "voxhammer_text_mesh_editing",
      label: "VoxHammer Text Mesh Editing",
      feature: "text_mesh_editing"
    },
    %{
      value: "voxhammer_image_mesh_editing",
      label: "VoxHammer Image Mesh Editing",
      feature: "image_mesh_editing"
    },
    %{
      value: "krea2_turbo_text_to_image",
      label: "Krea 2 Turbo Text-to-Image (local, recommended)",
      feature: "text_to_image"
    },
    %{
      value: "seethrough_layer_decomposition",
      label: "See-Through Layer Decomposition (anime → RGBA layers + depth)",
      feature: "image_to_layers"
    },
    %{
      value: "kimodo_text_to_motion",
      label: "Kimodo Text-to-Motion (SOMA → VRM)",
      feature: "text_to_motion"
    }
  ]
  @impl true
  def list_models(_state \\ nil), do: @entries

  @impl true
  def list_for_feature(_state \\ nil, feature) do
    Enum.filter(@entries, &(&1.feature == feature))
  end

  @impl true
  def list_features(_state \\ nil) do
    @entries |> Enum.map(& &1.feature) |> Enum.uniq() |> Enum.sort()
  end

  # Trust follows the RFD 0016 status. A vetoed model failed a licence
  # gate, so it keeps a floor score rather than leaving the store: the
  # veto is itself a fact worth holding.
  @trust %{active: 0.9, legacy: 0.4, vetoed: 0.1}

  @impl true
  def list_facts(state \\ nil) do
    labels = Map.new(list_models(state), &{&1.value, &1})

    WeftspunStudio.Inventory.all()
    |> Enum.reject(&(&1.group == :component))
    |> Enum.map(&to_fact(&1, labels))
  end

  @impl true
  def list_facts_above(state \\ nil, min_trust) do
    state
    |> list_facts()
    |> Enum.filter(&(&1.trust_score >= min_trust))
    |> Enum.sort_by(& &1.trust_score, :desc)
  end

  defp to_fact(model, labels) do
    entry = Map.get(labels, model.id)

    %{
      fact_id: model.id,
      content: (entry && entry.label) || model.task,
      category: (entry && entry.feature) || Atom.to_string(model.group),
      tags: tags_for(model),
      trust_score: Map.fetch!(@trust, model.status),
      updated_at: DateTime.from_unix!(0)
    }
  end

  defp tags_for(model) do
    [Atom.to_string(model.type), Atom.to_string(model.runs_on), Atom.to_string(model.status)]
    |> then(&if model.note, do: &1 ++ ["noted"], else: &1)
  end
end
