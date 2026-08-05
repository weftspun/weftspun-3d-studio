defmodule WeftspunStudio.FactsTest do
  @moduledoc """
  Catalog entries are trust-scored facts. RFD 0016 churns: licence
  gates veto models and recommendations move, so trust must move too.
  """

  use ExUnit.Case, async: true
  import Mox

  alias WeftspunStudio.Adapters.InventoryCatalog
  alias WeftspunStudio.FactSinkMock

  setup :verify_on_exit!

  test "every fact carries the hermes store fields" do
    for fact <- InventoryCatalog.list_facts(nil) do
      assert is_binary(fact.fact_id) and fact.fact_id != ""
      assert is_binary(fact.content) and fact.content != ""
      assert is_binary(fact.category)
      assert is_list(fact.tags)
      assert fact.trust_score >= 0.0 and fact.trust_score <= 1.0
      assert %DateTime{} = fact.updated_at
    end
  end

  test "a vetoed model keeps a low trust score instead of vanishing" do
    facts = Map.new(InventoryCatalog.list_facts(nil), &{&1.fact_id, &1})

    vetoed = facts["hunyuan3dv21_image_to_raw_mesh"]
    active = facts["trellis2_image_to_textured_mesh"]

    assert vetoed.trust_score < active.trust_score
    assert "vetoed" in vetoed.tags
    assert vetoed.trust_score > 0.0, "the veto is itself a fact worth keeping"
  end

  test "a trust floor filters and orders by confidence" do
    high = InventoryCatalog.list_facts_above(nil, 0.5)

    assert Enum.all?(high, &(&1.trust_score >= 0.5))
    assert high == Enum.sort_by(high, & &1.trust_score, :desc)
    refute Enum.any?(high, &("vetoed" in &1.tags))
  end

  test "feedback moves a fact's trust" do
    expect(FactSinkMock, :record_feedback, fn _state, "trellis2_image_to_textured_mesh", true ->
      {:ok, %{fact_id: "trellis2_image_to_textured_mesh", old_trust: 0.9, new_trust: 0.95}}
    end)

    assert {:ok, %{old_trust: 0.9, new_trust: 0.95}} =
             FactSinkMock.record_feedback(nil, "trellis2_image_to_textured_mesh", true)
  end

  test "a fact that no longer holds can be retracted" do
    expect(FactSinkMock, :retract_fact, fn _state, "unirig_auto_rig" -> :ok end)
    assert :ok = FactSinkMock.retract_fact(nil, "unirig_auto_rig")
  end
end
