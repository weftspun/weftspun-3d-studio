# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule WeftspunStudio.Repo do
  @moduledoc """
  The database connection for the studio core.

  RFD 0020 selects the V-Sekai CockroachDB build. CockroachDB speaks
  the PostgreSQL wire protocol, so `Ecto.Adapters.Postgres` drives it
  without a separate adapter.

  Two differences matter:

    * CockroachDB has no advisory lock, so `migration_lock: false`.
    * CockroachDB gives no `SERIAL` gap free sequence, so the tables
      here use a natural key instead of an integer id.
  """

  use Ecto.Repo,
    otp_app: :weftspun_studio,
    adapter: Ecto.Adapters.Postgres

  @doc "True when the pool holds a live connection."
  @spec up?() :: boolean()
  def up? do
    case Process.whereis(__MODULE__) do
      nil ->
        false

      _pid ->
        try do
          query!("SELECT 1", [])
          true
        rescue
          _ -> false
        end
    end
  end
end
