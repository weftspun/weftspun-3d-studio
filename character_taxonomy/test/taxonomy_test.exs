defmodule CharacterTaxonomy.TaxonomyTest do
  @moduledoc """
  `priv/repo/migrations/..._seed_taxonomy.exs` writes
  `CharacterTaxonomy.Seed`'s values once, at migrate time. These
  tests read that seed back, so the seed migration and the schema it
  fills stay in agreement. `CharacterTaxonomy.Seed` is the one
  source both read.
  """

  use ExUnit.Case, async: true

  alias CharacterTaxonomy.{Repo, Taxonomy}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    name = :"taxonomy_#{:erlang.phash2(make_ref())}"
    start_supervised!({Taxonomy, name: name, dim: 256})
    Taxonomy.hydrate(name)
    %{taxonomy: name}
  end

  test "hydrate loads every seeded category", %{taxonomy: t} do
    snapshot = Taxonomy.snapshot(t)

    for {role, values} <- CharacterTaxonomy.Seed.categories() do
      seeded_ids = Enum.map(values, &normalize/1) |> Enum.sort() |> Enum.uniq()
      assert Map.get(snapshot.categories, role) == seeded_ids
    end
  end

  test "hydrate loads every seeded numeric range", %{taxonomy: t} do
    snapshot = Taxonomy.snapshot(t)

    for {role, values} <- CharacterTaxonomy.Seed.numerics() do
      assert Map.get(snapshot.numerics, role) == [Enum.min(values) * 1.0, Enum.max(values) * 1.0]
    end
  end

  test "resolving a seeded value matches instead of minting", %{taxonomy: t} do
    assert {:ok, "black", :matched} = Taxonomy.resolve_or_mint(t, "hair_color", "black")
  end

  test "resolving a new value mints and persists it", %{taxonomy: t} do
    assert {:ok, "teal", :minted} = Taxonomy.resolve_or_mint(t, "hair_color", "teal")

    ids =
      CharacterTaxonomy.Capability
      |> Repo.all()
      |> Enum.filter(&(&1.role == "hair_color"))
      |> Enum.map(& &1.capability_id)

    assert "teal" in ids
  end

  test "observing a numeric value outside the seeded range widens it", %{taxonomy: t} do
    seeded = Taxonomy.snapshot(t).numerics["age"]
    [lo, hi] = seeded

    assert {^lo, new_hi} = Taxonomy.observe_numeric(t, "age", hi + 5)
    assert new_hi == hi + 5
  end

  defp normalize(text) do
    text
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/\s+/, "_")
  end
end
