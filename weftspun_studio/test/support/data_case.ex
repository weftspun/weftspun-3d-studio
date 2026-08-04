# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule WeftspunStudio.DataCase do
  @moduledoc """
  Test case for anything that reaches the database.

  Each test takes a sandbox connection and rolls it back at the end,
  so a test leaves no row behind. `async: true` gives the test its
  own connection.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Ecto
      import Ecto.Query
      import WeftspunStudio.DataCase

      alias WeftspunStudio.Repo
    end
  end

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(WeftspunStudio.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    :ok
  end
end
