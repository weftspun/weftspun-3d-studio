# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule WeftspunStudio.Repo.Migrations.ReencodeFactVectors do
  @moduledoc """
  Re-encodes every stored vector for the `hrr` library.

  RFD 0021 replaces the local real-valued HRR with the shared phase
  algebra. The old rows hold 1024 float32 values, and the new rows
  hold 1024 float64 phase angles. A reader cannot tell the two apart
  from the bytes, so the migration rewrites them.

  Trust scores survive, because the vector is derived from the other
  columns and never from itself.
  """

  use Ecto.Migration

  import Ecto.Query

  alias WeftspunStudio.{FactVector, Repo}

  def up do
    # `mix ecto.migrate` starts the repository alone, so EXLA is not
    # running. Phase encoding is hashing and arithmetic, so the pure
    # Elixir backend serves it.
    Nx.default_backend(Nx.BinaryBackend)

    # The vector is derived, so a full rewrite loses nothing.
    rows =
      Repo.all(from(f in "facts", select: {f.fact_id, f.category, f.tags}))

    Enum.each(rows, fn {fact_id, category, tags} ->
      vector =
        %{fact_id: fact_id, category: category, tags: tags || []}
        |> FactVector.encode()
        |> HRR.to_binary()

      Repo.update_all(
        from(f in "facts", where: f.fact_id == ^fact_id),
        set: [hrr_vector: vector]
      )
    end)
  end

  def down do
    # The earlier encoding is gone with the module that made it. A
    # rollback therefore clears the column, and a re-seed refills it.
    Repo.update_all(from(f in "facts"), set: [hrr_vector: nil])
  end
end
