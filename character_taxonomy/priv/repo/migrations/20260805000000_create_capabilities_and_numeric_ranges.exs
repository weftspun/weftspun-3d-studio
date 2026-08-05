defmodule CharacterTaxonomy.Repo.Migrations.CreateCapabilitiesAndNumericRanges do
  use Ecto.Migration

  def change do
    create table(:capabilities, primary_key: false) do
      add(:role, :string, primary_key: true, null: false)
      add(:capability_id, :string, primary_key: true, null: false)
      add(:hrr_vector, :binary, null: false)

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create table(:numeric_ranges, primary_key: false) do
      add(:role, :string, primary_key: true, null: false)
      add(:min, :float, null: false)
      add(:max, :float, null: false)

      timestamps(type: :utc_datetime_usec)
    end
  end
end
