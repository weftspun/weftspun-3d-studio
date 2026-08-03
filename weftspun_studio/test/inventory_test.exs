defmodule WeftspunStudio.InventoryTest do
  use ExUnit.Case, async: true

  alias WeftspunStudio.{Inventory, Model}

  test "every model carries the required fields" do
    for %Model{} = model <- Inventory.all() do
      assert is_binary(model.id) and model.id != ""
      assert model.type in [:deep_learning, :geometric]
      assert model.runs_on in [:dgx_api, :local, :external]
      assert model.group in [:core, :environment, :splat, :legacy, :component]
      assert model.status in [:active, :legacy, :vetoed]
    end
  end

  test "model ids are unique" do
    ids = Enum.map(Inventory.all(), & &1.id)
    assert length(ids) == length(Enum.uniq(ids))
  end

  test "RFD 0016 records two geometric algorithms outside the splat group" do
    geometric =
      Inventory.all()
      |> Enum.filter(&(&1.type == :geometric and &1.group != :splat))
      |> Enum.map(& &1.id)
      |> Enum.sort()

    assert geometric == ["instant_meshes_retopology", "xatlas_uv_unwrapping"]
  end

  test "COLMAP is the geometric splat entry" do
    assert {:ok, %Model{type: :geometric}} = Inventory.fetch("colmap_3dgs_reconstruct")
  end

  test "the Tencent licensed models are vetoed" do
    vetoed = Enum.map(Inventory.vetoed(), & &1.id)

    for id <- [
          "hunyuan3dv21_image_to_textured_mesh",
          "hunyuan3dv21_image_to_raw_mesh",
          "hunyuan3dv21_image_mesh_painting",
          "ultrashape_image_to_raw_mesh"
        ] do
      assert id in vetoed
    end
  end

  test "a vetoed model is never active" do
    refute Enum.any?(Inventory.active(), &Model.vetoed?/1)
  end

  test "See-Through components cover LaMa, SDXL, and Marigold" do
    notes = Enum.map_join(Inventory.see_through_components(), " ", &(&1.note || ""))

    assert notes =~ "LaMa"
    assert notes =~ "SDXL"
    assert notes =~ "Marigold"
  end

  test "See-Through components run locally" do
    for model <- Inventory.see_through_components() do
      assert model.runs_on == :local
      assert model.group == :component
    end
  end

  test "fetch returns :error for an unknown id" do
    assert :error = Inventory.fetch("no_such_model")
  end
end
