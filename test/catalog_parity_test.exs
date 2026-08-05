defmodule WeftspunStudio.CatalogParityTest do
  @moduledoc """
  The served catalog must match the client catalog exactly, because
  phase 1 of RFD 0019 changes no behavior.
  """

  use ExUnit.Case, async: true

  alias WeftspunStudio.Adapters.InventoryCatalog

  @catalog "thirdparty/3d_studio/src/library/aiModelsCatalog.js"

  test "every served id appears in the client catalog" do
    assert {:ok, js_ids} = WeftspunStudio.JsCatalog.ids(@catalog)
    served = InventoryCatalog.list_models(nil) |> Enum.map(& &1.value) |> Enum.sort()

    assert served == Enum.sort(js_ids)
  end

  test "entries carry a non-empty label and feature" do
    for entry <- InventoryCatalog.list_models(nil) do
      assert entry.label != "", "#{entry.value} has no label"
      assert entry.feature != "", "#{entry.value} has no feature"
    end
  end

  test "list_for_feature agrees with the full list" do
    all = InventoryCatalog.list_models(nil)

    for feature <- InventoryCatalog.list_features(nil) do
      expected = Enum.filter(all, &(&1.feature == feature))
      assert InventoryCatalog.list_for_feature(nil, feature) == expected
    end
  end
end
