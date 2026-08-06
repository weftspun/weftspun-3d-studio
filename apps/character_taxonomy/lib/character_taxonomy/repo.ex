# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule CharacterTaxonomy.Repo do
  @moduledoc """
  The database connection for this service, in
  `WeftspunStudio.Repo`'s own style, on its own CockroachDB.

  RFD 0065's taxonomy must survive a restart and a redeploy, so it
  is not `CharacterTaxonomy.Taxonomy`'s Agent state alone. That Agent
  stays as the read-path cache. This repo is the write-through and
  the boot-time hydration source.
  """

  use Ecto.Repo,
    otp_app: :character_taxonomy,
    adapter: Ecto.Adapters.Postgres
end
