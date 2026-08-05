defmodule CharacterTaxonomy.Repo.Migrations.SeedTaxonomy do
  @moduledoc """
  The first-boot seed, as a migration, not an `Application.start/2`
  side effect. `CharacterTaxonomy.Seed` stays the one source for the
  values, so this migration and any later test both read the same
  list. `mix ecto.migrate` runs it once, tracked in
  `schema_migrations` the way every other migration is.
  """

  use Ecto.Migration

  alias CharacterTaxonomy.Repo

  def up do
    dim = HRR.default_dim()
    now = DateTime.utc_now()

    for {role, values} <- CharacterTaxonomy.Seed.categories(), value <- values do
      id = normalize(value)
      vector = HRR.encode_atom(id, dim)

      Repo.insert_all(
        "capabilities",
        [%{role: role, capability_id: id, hrr_vector: HRR.to_binary(vector), inserted_at: now}],
        on_conflict: :nothing,
        conflict_target: [:role, :capability_id]
      )
    end

    for {role, values} <- CharacterTaxonomy.Seed.numerics() do
      Repo.insert_all(
        "numeric_ranges",
        [%{role: role, min: Enum.min(values) * 1.0, max: Enum.max(values) * 1.0, inserted_at: now, updated_at: now}],
        on_conflict: {:replace, [:min, :max, :updated_at]},
        conflict_target: [:role]
      )
    end
  end

  def down do
    execute("DELETE FROM capabilities")
    execute("DELETE FROM numeric_ranges")
  end

  defp normalize(text) do
    text
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/\s+/, "_")
  end
end
