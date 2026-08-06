# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule WeftspunStudio.Facts.Fact do
  @moduledoc """
  One trust scored catalog fact, as a database row.

  The shape follows the hermes-agent holographic memory store. The
  model id is the primary key, because a catalog fact already has a
  natural key and CockroachDB gives no gap free integer sequence.

  `hrr_vector` holds the packed float64 phase vector from
  `WeftspunStudio.FactVector.encode/2`. The column is `bytea`, so the
  width stays fixed and the row stays small. `to_tensor/1` unpacks it.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias WeftspunStudio.FactVector

  @type t :: %__MODULE__{}

  @primary_key {:fact_id, :string, autogenerate: false}
  @derive {Jason.Encoder, only: [:fact_id, :content, :category, :tags, :trust_score, :updated_at]}

  schema "facts" do
    field(:content, :string)
    field(:category, :string)
    field(:tags, {:array, :string}, default: [])
    field(:trust_score, :float, default: 0.5)
    field(:hrr_vector, :binary)

    timestamps(type: :utc_datetime_usec)
  end

  @required [:fact_id, :content, :category]
  @optional [:tags, :trust_score, :hrr_vector]

  @doc """
  Validates a fact and packs its HRR vector.

  The vector is derived, never supplied. Encoding it here keeps the
  row and the algebra in step, because no caller can write a fact
  whose vector disagrees with its fields.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(fact, attrs) do
    fact
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_number(:trust_score, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0)
    |> put_vector()
  end

  defp put_vector(changeset) do
    if changeset.valid? do
      encoded =
        changeset
        |> apply_changes()
        |> Map.take([:fact_id, :category, :tags])
        |> FactVector.encode()
        |> HRR.to_binary()

      put_change(changeset, :hrr_vector, encoded)
    else
      changeset
    end
  end

  @doc "Unpacks the stored HRR vector back into a tensor."
  @spec to_tensor(t()) :: Nx.Tensor.t()
  def to_tensor(%__MODULE__{hrr_vector: binary}) when is_binary(binary) do
    HRR.from_binary(binary)
  end
end
