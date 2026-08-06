# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule CharacterTaxonomy.NumericRange do
  @moduledoc """
  The observed `[min, max]` for one numeric role, as a database row.

  A numeric role, such as `height_cm`, creates nothing. This row is
  the taxonomy's only durable state for it, and `role` is a natural
  key on its own.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @primary_key {:role, :string, autogenerate: false}
  schema "numeric_ranges" do
    field(:min, :float)
    field(:max, :float)

    timestamps(type: :utc_datetime_usec)
  end

  @required [:role, :min, :max]

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(range, attrs) do
    range
    |> cast(attrs, @required)
    |> validate_required(@required)
  end
end
