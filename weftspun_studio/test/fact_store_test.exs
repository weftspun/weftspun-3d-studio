defmodule WeftspunStudio.FactStoreTest do
  @moduledoc """
  The RFD 0016 inventory seeds the store. Trust then moves with use.
  """

  use ExUnit.Case, async: true

  alias WeftspunStudio.FactStore

  setup context do
    name = :"store_#{:erlang.phash2(context.test)}"
    start_supervised!({FactStore, name: name, dim: 512})
    %{store: name}
  end

  test "the inventory seeds the store", %{store: s} do
    facts = FactStore.list(s)

    # RFD 0016 records 29 non-component models. The client catalog
    # carries 28, so the seed leads the client by one.
    assert length(facts) == 29
    assert Enum.all?(facts, &Map.has_key?(&1, :hrr_vector))
    assert facts == Enum.sort_by(facts, & &1.trust_score, :desc)
  end

  test "the seed leads the client catalog by the known drift", %{store: s} do
    seeded = FactStore.list(s) |> Enum.map(& &1.fact_id) |> MapSet.new()
    {:ok, client} = WeftspunStudio.JsCatalog.ids("../src/library/aiModelsCatalog.js")

    assert MapSet.difference(seeded, MapSet.new(client)) ==
             MapSet.new(["qwen_q4_k_m_image_edit"])
  end

  test "a seeded fact keeps its HRR structure", %{store: s} do
    assert {"image_to_textured_mesh", score} =
             FactStore.probe_role(s, "trellis2_image_to_textured_mesh", :category)

    assert score > 0.3
  end

  test "the id role recovers the id", %{store: s} do
    assert {"xatlas_uv_unwrapping", _} = FactStore.probe_role(s, "xatlas_uv_unwrapping", :id)
  end

  test "search ranks a matching category first", %{store: s} do
    assert [{fact, _score} | _] = FactStore.search(s, "uv_unwrapping", limit: 3)
    assert fact.fact_id == "xatlas_uv_unwrapping"
  end

  test "a trust floor hides vetoed facts from search", %{store: s} do
    results = FactStore.search(s, "hunyuan3dv21_image_to_raw_mesh", limit: 10, min_trust: 0.5)

    refute Enum.any?(results, fn {f, _} -> "vetoed" in f.tags end)
  end

  test "helpful feedback raises trust and unhelpful lowers it", %{store: s} do
    id = "trellis2_image_to_textured_mesh"

    assert {:ok, %{old_trust: old, new_trust: up}} = FactStore.record_feedback(s, id, true)
    assert up > old

    assert {:ok, %{old_trust: ^up, new_trust: down}} = FactStore.record_feedback(s, id, false)
    assert down < up
  end

  test "trust stays inside zero and one", %{store: s} do
    id = "unirig_auto_rig"
    for _ <- 1..40, do: FactStore.record_feedback(s, id, false)

    assert {:ok, fact} = FactStore.fetch(s, id)
    assert fact.trust_score >= 0.0
  end

  test "feedback on an unknown fact reports not found", %{store: s} do
    assert {:error, :not_found} = FactStore.record_feedback(s, "nope", true)
  end

  test "a new fact can be added and found", %{store: s} do
    :ok =
      FactStore.upsert_fact(s, "new_model", %{
        content: "New Model",
        category: "text_to_3d",
        tags: ["deep_learning", "active"],
        trust_score: 0.8,
        updated_at: DateTime.from_unix!(0)
      })

    assert {:ok, %{trust_score: 0.8}} = FactStore.fetch(s, "new_model")
    assert [{%{fact_id: "new_model"}, _} | _] = FactStore.search(s, "text_to_3d", limit: 3)
  end

  test "a retracted fact leaves the store", %{store: s} do
    :ok = FactStore.retract_fact(s, "unirig_auto_rig")
    assert :error = FactStore.fetch(s, "unirig_auto_rig")
  end
end
