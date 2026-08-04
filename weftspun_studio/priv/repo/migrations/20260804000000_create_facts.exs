# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule WeftspunStudio.Repo.Migrations.CreateFacts do
  use Ecto.Migration

  def change do
    create table(:facts, primary_key: false) do
      add(:fact_id, :string, primary_key: true)
      add(:content, :text, null: false)
      add(:category, :string, null: false)
      add(:tags, {:array, :string}, null: false, default: [])
      add(:trust_score, :float, null: false, default: 0.5)
      # The packed float32 HRR vector. See WeftspunStudio.Facts.Fact.
      add(:hrr_vector, :binary)

      timestamps(type: :utc_datetime_usec)
    end

    # The catalog reads by feature, and the trust floor filters the
    # result, so both queries hit this index.
    create(index(:facts, [:category]))
    create(index(:facts, [:trust_score]))
  end
end
