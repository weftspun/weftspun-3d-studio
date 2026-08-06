# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule CharacterTaxonomy.Taxonomy do
  @moduledoc """
  RFD 0065's data-driven trait taxonomy for RFD 0064's character
  concept generator.

  Holds no fixed capability list. A caller resolves a trait value
  observed in one dataset row, and this module returns an existing
  capability id on a near match, or creates a new one. The taxonomy
  grows from the training data instead of a preconceived category
  list.

  Categorical roles (`hair_color`, `eye_color`, `pose`, `clothing`)
  go through `HRR`/`HRR.Cleanup`, the library RFD 0021 supplies. A
  near-duplicate caption phrase binds to the same vector
  neighborhood and resolves to the existing id.

  Numeric roles (`height_cm`, `age`) carry no taxonomy to create.
  This module tracks the observed range instead, so the static
  randomizer page can pick inside it.

  The Agent holds the read-path cache only. `CharacterTaxonomy.Repo`
  is the durable store, on CockroachDB, so a created id or a widened
  range survives a restart and a redeploy. `hydrate/1` rebuilds the
  cache from the database at boot.
  """

  use Agent

  alias CharacterTaxonomy.{Capability, NumericRange, Repo}

  @default_dim HRR.default_dim()
  @default_threshold 0.85

  @doc "Starts the taxonomy with an empty cache. Call `hydrate/1` after."
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    dim = Keyword.get(opts, :dim, @default_dim)
    Agent.start_link(fn -> %{dim: dim, codebooks: %{}, numerics: %{}} end, name: name)
  end

  @doc """
  Loads every row `CharacterTaxonomy.Repo` already holds into the
  cache. Idempotent, so a caller may run it again after a migration.
  """
  @spec hydrate(GenServer.name()) :: :ok
  def hydrate(name \\ __MODULE__) do
    capabilities = Repo.all(Capability)
    ranges = Repo.all(NumericRange)

    Agent.update(name, fn %{dim: dim} = state ->
      books =
        Enum.reduce(capabilities, %{}, fn cap, acc ->
          book = Map.get(acc, cap.role, %{})
          probe = HRR.encode_atom(cap.capability_id, dim)
          Map.put(acc, cap.role, Map.put(book, cap.capability_id, probe))
        end)

      numerics = Map.new(ranges, fn r -> {r.role, {r.min, r.max}} end)

      %{state | codebooks: books, numerics: numerics}
    end)

    :ok
  end

  @doc """
  Resolves `text` under `role` to a capability id.

  Returns `{:ok, id, :matched}` when an existing id in the role's
  codebook clears `threshold`, or `{:ok, id, :created}` when this
  call adds a new one and persists it to `CharacterTaxonomy.Repo`.
  `id` is the normalized text when this call creates one, so a human
  reading `problem.ex` still sees a plain word for a first sighting.
  """
  @spec resolve_or_create(GenServer.name(), String.t(), String.t(), float()) ::
          {:ok, String.t(), :matched | :created}
  def resolve_or_create(name \\ __MODULE__, role, text, threshold \\ @default_threshold) do
    id = normalize(text)

    result =
      Agent.get_and_update(name, fn %{dim: dim, codebooks: books} = state ->
        book = Map.get(books, role, %{})
        probe = HRR.encode_atom(id, dim)

        case HRR.Cleanup.nearest_above(probe, book, threshold) do
          {existing_id, _score} ->
            {{:ok, existing_id, :matched}, state}

          nil ->
            book = Map.put(book, id, probe)
            {{:ok, id, :created, probe}, %{state | codebooks: Map.put(books, role, book)}}
        end
      end)

    case result do
      {:ok, created_id, :created, probe} ->
        persist_capability(role, created_id, probe)
        {:ok, created_id, :created}

      matched ->
        matched
    end
  end

  @doc "Records one numeric observation, widens the role's range, and persists it."
  @spec observe_numeric(GenServer.name(), String.t(), number()) :: {number(), number()}
  def observe_numeric(name \\ __MODULE__, role, value) do
    range =
      Agent.get_and_update(name, fn %{numerics: numerics} = state ->
        range =
          case Map.get(numerics, role) do
            nil -> {value, value}
            {lo, hi} -> {min(lo, value), max(hi, value)}
          end

        {range, %{state | numerics: Map.put(numerics, role, range)}}
      end)

    persist_numeric_range(role, range)
    range
  end

  @doc """
  The taxonomy as plain data, for the `/api/v1/traits` headless-CMS
  route, the MCP `taxonomy_snapshot` tool, and the static randomizer
  page.

  `categories` maps each role to the capability ids created so far.
  `numerics` maps each role to `[min, max]`.
  """
  @spec snapshot(GenServer.name()) :: %{categories: map(), numerics: map()}
  def snapshot(name \\ __MODULE__) do
    Agent.get(name, fn %{codebooks: books, numerics: numerics} ->
      %{
        categories: Map.new(books, fn {role, book} -> {role, Map.keys(book) |> Enum.sort()} end),
        numerics: Map.new(numerics, fn {role, {lo, hi}} -> {role, [lo, hi]} end)
      }
    end)
  end

  defp persist_capability(role, capability_id, probe) do
    %Capability{}
    |> Capability.changeset(%{
      role: role,
      capability_id: capability_id,
      hrr_vector: HRR.to_binary(probe)
    })
    |> Repo.insert(
      on_conflict: :nothing,
      conflict_target: [:role, :capability_id]
    )
  end

  defp persist_numeric_range(role, {lo, hi}) do
    %NumericRange{role: role}
    |> NumericRange.changeset(%{role: role, min: lo * 1.0, max: hi * 1.0})
    |> Repo.insert(
      on_conflict: {:replace, [:min, :max, :updated_at]},
      conflict_target: [:role]
    )
  end

  defp normalize(text) do
    text
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/\s+/, "_")
  end
end
