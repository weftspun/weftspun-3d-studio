# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule CharacterTaxonomy.Capability do
  @moduledoc """
  One minted capability id, as a database row.

  The composite key is `{role, capability_id}`, because a mint is a
  natural key already, per RFD 0065's rule against a fixed enum. The
  packed HRR atom vector lets a restarted node rebuild the codebook
  it needs for `HRR.Cleanup.nearest_above/3` with no re-encoding.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @primary_key false
  schema "capabilities" do
    field(:role, :string, primary_key: true)
    field(:capability_id, :string, primary_key: true)
    field(:hrr_vector, :binary)

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  @required [:role, :capability_id, :hrr_vector]

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(capability, attrs) do
    capability
    |> cast(attrs, @required)
    |> validate_required(@required)
  end
end
