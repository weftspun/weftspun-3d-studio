defmodule WeftspunStudio.JsCatalogTest do
  use ExUnit.Case, async: true

  alias WeftspunStudio.JsCatalog

  @fixture Path.join(System.tmp_dir!(), "weftspun_catalog_test.js")

  setup do
    on_exit(fn -> File.rm(@fixture) end)
    :ok
  end

  defp write!(source), do: File.write!(@fixture, source)

  test "reads ids from single and double quoted entries" do
    write!("""
    export const ALL_MODELS = [
      { value: 'trellis2_image_to_textured_mesh', label: 'A', feature: 'x' },
      { value: "xatlas_uv_unwrapping", label: 'B', feature: 'y' },
    ];
    """)

    assert {:ok, ids} = JsCatalog.ids(@fixture)
    assert ids == ["trellis2_image_to_textured_mesh", "xatlas_uv_unwrapping"]
  end

  test "de-duplicates repeated ids" do
    write!("""
    { value: 'p3sam_mesh_segmentation' }
    { value: 'p3sam_mesh_segmentation' }
    """)

    assert {:ok, ["p3sam_mesh_segmentation"]} = JsCatalog.ids(@fixture)
  end

  test "reports ids missing from each side" do
    write!("{ value: 'trellis2_image_to_textured_mesh' }\n{ value: 'brand_new_model' }\n")

    assert {:ok, diff} = JsCatalog.diff(@fixture)
    assert "brand_new_model" in diff.only_in_js
    assert "trellis2_image_to_textured_mesh" in diff.both
    assert "kimodo_text_to_motion" in diff.only_in_elixir
  end

  test "component ids are excluded from the parity check" do
    write!("{ value: 'trellis2_image_to_textured_mesh' }\n")

    assert {:ok, diff} = JsCatalog.diff(@fixture)
    refute Enum.any?(diff.only_in_elixir, &String.starts_with?(&1, "seethrough."))
  end

  test "returns an error when the catalog is absent" do
    assert {:error, :enoent} = JsCatalog.ids("/no/such/catalog.js")
    assert {:error, :enoent} = JsCatalog.diff("/no/such/catalog.js")
    refute JsCatalog.in_parity?("/no/such/catalog.js")
  end
end
