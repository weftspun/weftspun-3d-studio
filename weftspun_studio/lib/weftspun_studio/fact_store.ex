# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule WeftspunStudio.FactStore do
  @moduledoc """
  Trust-scored catalog facts held in memory, with HRR retrieval.

  The RFD 0016 inventory is the seed database. The store loads it at
  boot, encodes each fact to an HRR vector, and serves queries from
  there. Later writes move trust or retract a fact, so the seed is a
  starting point and not a fixed table.

  This implements `WeftspunStudio.Ports.FactSink`. The state handle is
  the process name, matching the port contract.
  """

  use Agent

  alias WeftspunStudio.{Adapters.InventoryCatalog, Hrr}

  @behaviour WeftspunStudio.Ports.FactSink

  @doc "Starts the store and seeds it from the inventory."
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    dim = Keyword.get(opts, :dim, Hrr.default_dim())
    seed = Keyword.get_lazy(opts, :seed, fn -> InventoryCatalog.list_facts(nil) end)

    Agent.start_link(fn -> build(seed, dim) end, name: name)
  end

  defp build(seed, dim) do
    facts =
      Map.new(seed, fn fact ->
        {fact.fact_id, Map.put(fact, :hrr_vector, Hrr.encode_fact(fact, dim))}
      end)

    %{dim: dim, facts: facts, codebook: Hrr.codebook(seed, dim)}
  end

  @doc "Every fact, highest trust first."
  def list(name \\ __MODULE__) do
    Agent.get(name, fn %{facts: facts} ->
      facts |> Map.values() |> Enum.sort_by(& &1.trust_score, :desc)
    end)
  end

  @doc "One fact by id."
  def fetch(name \\ __MODULE__, fact_id) do
    Agent.get(name, fn %{facts: facts} -> Map.fetch(facts, fact_id) end)
  end

  @doc """
  Ranks facts against a free-text query by HRR similarity.

  The query encodes as a bundle of its terms. Trust breaks ties, so a
  vetoed fact sinks below an equally similar active one.
  """
  def search(name \\ __MODULE__, query, opts \\ []) do
    limit = Keyword.get(opts, :limit, 5)
    min_trust = Keyword.get(opts, :min_trust, 0.0)

    Agent.get(name, fn %{dim: dim, facts: facts} ->
      probe = query_vector(query, dim)

      facts
      |> Map.values()
      |> Enum.filter(&(&1.trust_score >= min_trust))
      |> Enum.map(fn fact ->
        score = Nx.to_number(Hrr.similarity(probe, fact.hrr_vector))
        {fact, score * fact.trust_score}
      end)
      |> Enum.sort_by(&elem(&1, 1), :desc)
      |> Enum.take(limit)
    end)
  end

  defp query_vector(query, dim) do
    terms =
      query
      |> String.downcase()
      |> String.split(~r/[^a-z0-9_.]+/u, trim: true)

    case terms do
      [] ->
        Nx.broadcast(0.0, {dim})

      terms ->
        Hrr.bundle(
          Enum.flat_map(terms, fn t ->
            [
              Hrr.bind(Hrr.role(:id, dim), Hrr.vector(t, dim)),
              Hrr.bind(Hrr.role(:category, dim), Hrr.vector(t, dim)),
              Hrr.bind(Hrr.role(:tag, dim), Hrr.vector(t, dim))
            ]
          end)
        )
    end
  end

  @doc "Recovers the symbol bound to one role of a stored fact."
  def probe_role(name \\ __MODULE__, fact_id, role) do
    Agent.get(name, fn %{dim: dim, facts: facts, codebook: codebook} ->
      case Map.fetch(facts, fact_id) do
        {:ok, fact} ->
          fact.hrr_vector |> Hrr.unbind(Hrr.role(role, dim)) |> Hrr.cleanup(codebook)

        :error ->
          nil
      end
    end)
  end

  @impl true
  def upsert_fact(name, fact_id, attrs) do
    Agent.update(name, fn %{dim: dim, facts: facts, codebook: codebook} = state ->
      fact = attrs |> Map.put(:fact_id, fact_id) |> then(&Map.put(&1, :hrr_vector, Hrr.encode_fact(&1, dim)))

      %{
        state
        | facts: Map.put(facts, fact_id, fact),
          codebook: Map.merge(codebook, Hrr.codebook([fact], dim))
      }
    end)
  end

  @impl true
  def record_feedback(name, fact_id, helpful?) do
    Agent.get_and_update(name, fn %{facts: facts} = state ->
      case Map.fetch(facts, fact_id) do
        {:ok, fact} ->
          old = fact.trust_score
          delta = if helpful?, do: 0.05, else: -0.10
          new = old |> Kernel.+(delta) |> max(0.0) |> min(1.0)

          updated = Map.put(fact, :trust_score, new)

          {{:ok, %{fact_id: fact_id, old_trust: old, new_trust: new}},
           %{state | facts: Map.put(facts, fact_id, updated)}}

        :error ->
          {{:error, :not_found}, state}
      end
    end)
  end

  @impl true
  def retract_fact(name, fact_id) do
    Agent.update(name, fn %{facts: facts} = state ->
      %{state | facts: Map.delete(facts, fact_id)}
    end)
  end
end
