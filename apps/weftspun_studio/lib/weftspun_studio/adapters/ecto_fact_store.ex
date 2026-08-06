# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule WeftspunStudio.Adapters.EctoFactStore do
  @moduledoc """
  Driven adapter: trust scored facts held in CockroachDB.

  This is the durable twin of `WeftspunStudio.FactStore`. The Agent
  store rebuilds from the RFD 0016 inventory at every boot, so a
  trust change dies with the node. This adapter keeps the change.

  The retrieval stays the same. `seed/0` writes the inventory once,
  `search/2` ranks rows by HRR similarity against the query, and
  trust weights the result. RFD 0020 records the move.

  `state` is unused, because the repository is a named process. The
  argument stays to satisfy `WeftspunStudio.Ports.FactSink`.
  """

  import Ecto.Query

  alias WeftspunStudio.{Adapters.InventoryCatalog, FactVector, Facts.Fact, Repo}

  @behaviour WeftspunStudio.Ports.FactSink

  @helpful_delta 0.05
  @unhelpful_delta -0.10

  @doc """
  Writes the RFD 0016 inventory into the database.

  The seed is the starting point, not a fixed table. Running it again
  refreshes the seeded rows and adds no duplicate, because the model
  id is the primary key. Returns the row count.
  """
  @spec seed(keyword()) :: {:ok, non_neg_integer()}
  def seed(opts \\ []) do
    facts = Keyword.get_lazy(opts, :facts, fn -> InventoryCatalog.list_facts(nil) end)

    Enum.each(facts, fn fact ->
      :ok = upsert_fact(nil, fact.fact_id, fact)
    end)

    {:ok, Repo.aggregate(Fact, :count)}
  end

  @doc "Every fact, highest trust first."
  @spec list(keyword()) :: [Fact.t()]
  def list(opts \\ []) do
    min_trust = Keyword.get(opts, :min_trust, 0.0)

    Fact
    |> where([f], f.trust_score >= ^min_trust)
    |> order_by([f], desc: f.trust_score, asc: f.fact_id)
    |> Repo.all()
  end

  @doc "One fact by id."
  @spec fetch(String.t()) :: {:ok, Fact.t()} | :error
  def fetch(fact_id) do
    case Repo.get(Fact, fact_id) do
      nil -> :error
      fact -> {:ok, fact}
    end
  end

  @doc """
  Ranks facts against a free text query by HRR similarity.

  The database narrows the candidates by the trust floor. The algebra
  then scores them, because a cosine over a packed tensor has no SQL
  form here. Trust weights the score, so a vetoed fact sinks below an
  equally similar active one.
  """
  @spec search(String.t(), keyword()) :: [{Fact.t(), float()}]
  def search(query, opts \\ []) do
    limit = Keyword.get(opts, :limit, 5)
    min_trust = Keyword.get(opts, :min_trust, 0.0)
    dim = Keyword.get(opts, :dim, FactVector.default_dim())

    probe = query_vector(query, dim)

    list(min_trust: min_trust)
    |> Enum.map(fn fact ->
      score = HRR.similarity(probe, Fact.to_tensor(fact))
      {fact, score * fact.trust_score}
    end)
    |> Enum.sort_by(&elem(&1, 1), :desc)
    |> Enum.take(limit)
  end

  defp query_vector(query, dim), do: FactVector.query(query, dim)

  @doc """
  Recovers the symbol bound to one role of a stored fact.

  The codebook comes from the rows themselves, so cleanup can only
  return a symbol the database holds.
  """
  @spec probe_role(String.t(), atom(), keyword()) :: {String.t(), float()} | nil
  def probe_role(fact_id, role, opts \\ []) do
    dim = Keyword.get(opts, :dim, FactVector.default_dim())

    case fetch(fact_id) do
      {:ok, fact} ->
        fact
        |> Fact.to_tensor()
        |> FactVector.probe(role, codebook(dim), dim)

      :error ->
        nil
    end
  end

  @doc "Every symbol the stored facts can resolve to."
  @spec codebook(pos_integer()) :: %{String.t() => Nx.Tensor.t()}
  def codebook(dim \\ FactVector.default_dim()) do
    Fact
    |> select([f], {f.fact_id, f.category, f.tags})
    |> Repo.all()
    |> Enum.flat_map(fn {id, category, tags} -> [id, category | tags] end)
    |> HRR.Cleanup.codebook(dim)
  end

  @impl true
  def upsert_fact(_state, fact_id, attrs) do
    changeset =
      (Repo.get(Fact, fact_id) || %Fact{})
      |> Fact.changeset(
        attrs
        |> Map.new(fn {k, v} -> {to_string(k), v} end)
        |> Map.put("fact_id", fact_id)
      )

    case Repo.insert_or_update(changeset) do
      {:ok, _fact} -> :ok
      {:error, changeset} -> {:error, changeset}
    end
  end

  @impl true
  def record_feedback(_state, fact_id, helpful?) do
    case fetch(fact_id) do
      {:ok, fact} ->
        old = fact.trust_score
        delta = if helpful?, do: @helpful_delta, else: @unhelpful_delta
        new = old |> Kernel.+(delta) |> max(0.0) |> min(1.0)

        fact
        |> Ecto.Changeset.change(trust_score: new)
        |> Repo.update!()

        {:ok, %{fact_id: fact_id, old_trust: old, new_trust: new}}

      :error ->
        {:error, :not_found}
    end
  end

  @impl true
  def retract_fact(_state, fact_id) do
    case fetch(fact_id) do
      {:ok, fact} ->
        Repo.delete!(fact)
        :ok

      :error ->
        {:error, :not_found}
    end
  end
end
