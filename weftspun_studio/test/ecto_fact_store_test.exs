# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule WeftspunStudio.EctoFactStoreTest do
  use WeftspunStudio.DataCase, async: false

  alias WeftspunStudio.Adapters.EctoFactStore
  alias WeftspunStudio.{FactVector, Repo}
  alias WeftspunStudio.Facts.Fact

  describe "seed/0" do
    test "loads the RFD 0016 inventory into the database" do
      assert Repo.aggregate(Fact, :count) == 0

      {:ok, count} = EctoFactStore.seed()

      assert count > 0
      assert Repo.aggregate(Fact, :count) == count
    end

    test "runs twice without duplicating a row" do
      {:ok, count} = EctoFactStore.seed()
      {:ok, ^count} = EctoFactStore.seed()

      assert Repo.aggregate(Fact, :count) == count
    end

    test "stores an HRR vector of the configured width" do
      {:ok, _} = EctoFactStore.seed()

      fact = Repo.one!(Ecto.Query.from(f in Fact, limit: 1))

      assert Nx.axis_size(Fact.to_tensor(fact), 0) == FactVector.default_dim()
    end
  end

  describe "list/1 and fetch/1" do
    setup do
      {:ok, _} = EctoFactStore.seed()
      :ok
    end

    test "list returns the highest trust first" do
      scores = EctoFactStore.list() |> Enum.map(& &1.trust_score)

      assert scores == Enum.sort(scores, :desc)
    end

    test "fetch finds a seeded fact" do
      assert {:ok, fact} = EctoFactStore.fetch("trellis_text_to_textured_mesh")
      assert fact.category == "text_to_textured_mesh"
      assert fact.trust_score > 0.0
    end

    test "fetch reports a missing fact" do
      assert :error = EctoFactStore.fetch("no_such_model")
    end
  end

  describe "search/2" do
    setup do
      {:ok, _} = EctoFactStore.seed()
      :ok
    end

    test "ranks a matching fact first" do
      assert [{fact, score} | _] = EctoFactStore.search("uv_unwrapping", limit: 3)

      assert fact.category == "uv_unwrapping" or String.contains?(fact.fact_id, "uv")
      assert score > 0.0
    end

    test "honours the limit" do
      assert length(EctoFactStore.search("mesh", limit: 2)) == 2
    end

    test "drops facts below the trust floor" do
      results = EctoFactStore.search("mesh", limit: 50, min_trust: 0.8)

      assert Enum.all?(results, fn {fact, _} -> fact.trust_score >= 0.8 end)
    end
  end

  describe "the FactSink port" do
    setup do
      {:ok, _} = EctoFactStore.seed()
      :ok
    end

    test "upsert_fact writes a new fact and its vector" do
      attrs = %{
        content: "A test model.",
        category: "testing",
        tags: ["geometric", "local"],
        trust_score: 0.5
      }

      assert :ok = EctoFactStore.upsert_fact(nil, "test_model", attrs)
      assert {:ok, fact} = EctoFactStore.fetch("test_model")
      assert fact.content == "A test model."
      assert Nx.axis_size(Fact.to_tensor(fact), 0) == FactVector.default_dim()
    end

    test "upsert_fact replaces an existing fact" do
      before = Repo.aggregate(Fact, :count)

      :ok =
        EctoFactStore.upsert_fact(nil, "trellis_text_to_textured_mesh", %{
          content: "Replaced.",
          category: "text_to_textured_mesh",
          tags: [],
          trust_score: 0.2
        })

      assert Repo.aggregate(Fact, :count) == before
      assert {:ok, fact} = EctoFactStore.fetch("trellis_text_to_textured_mesh")
      assert fact.content == "Replaced."
      assert_in_delta fact.trust_score, 0.2, 0.0001
    end

    test "record_feedback moves the trust score" do
      {:ok, before} = EctoFactStore.fetch("trellis_text_to_textured_mesh")

      assert {:ok, result} =
               EctoFactStore.record_feedback(nil, "trellis_text_to_textured_mesh", true)

      assert_in_delta result.old_trust, before.trust_score, 0.0001
      assert_in_delta result.new_trust, before.trust_score + 0.05, 0.0001

      assert {:ok, after_fact} = EctoFactStore.fetch("trellis_text_to_textured_mesh")
      assert_in_delta after_fact.trust_score, result.new_trust, 0.0001
    end

    test "record_feedback clamps to the zero to one range" do
      :ok =
        EctoFactStore.upsert_fact(nil, "edge_model", %{
          content: "Edge.",
          category: "testing",
          tags: [],
          trust_score: 0.99
        })

      {:ok, %{new_trust: high}} = EctoFactStore.record_feedback(nil, "edge_model", true)
      assert high == 1.0

      :ok =
        EctoFactStore.upsert_fact(nil, "edge_model", %{
          content: "Edge.",
          category: "testing",
          tags: [],
          trust_score: 0.05
        })

      {:ok, %{new_trust: low}} = EctoFactStore.record_feedback(nil, "edge_model", false)
      assert low == 0.0
    end

    test "record_feedback reports a missing fact" do
      assert {:error, :not_found} = EctoFactStore.record_feedback(nil, "no_such_model", true)
    end

    test "retract_fact deletes the row" do
      :ok = EctoFactStore.retract_fact(nil, "trellis_text_to_textured_mesh")

      assert :error = EctoFactStore.fetch("trellis_text_to_textured_mesh")
    end
  end

  describe "probe_role/2" do
    setup do
      {:ok, _} = EctoFactStore.seed()
      :ok
    end

    test "recovers the category bound into a stored fact" do
      assert {token, score} = EctoFactStore.probe_role("trellis_text_to_textured_mesh", :category)

      assert token == "text_to_textured_mesh"
      assert score > 0.3
    end
  end
end
