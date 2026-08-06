# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule CharacterTaxonomy.Application do
  @moduledoc """
  Two listeners: the MCP server (RFD 0065's tools), and the
  headless-CMS HTTP surface (the taxonomy route and the static
  randomizer page). One Fly.io app, one release, one supervision
  tree, and a separate deploy target from `weftspun_studio`.

  `CharacterTaxonomy.Repo` runs first, and `Taxonomy.hydrate/1` loads
  its rows into the cache before either listener opens a port. A
  created id or a widened range then survives a restart or a
  redeploy, the reason this service runs its own CockroachDB instead
  of an Agent alone.

  The first-boot seed is `priv/repo/migrations/..._seed_taxonomy.exs`,
  not a step here. `mix ecto.migrate` runs it once and tracks it in
  `schema_migrations`, the same way it tracks the table creation.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [CharacterTaxonomy.Repo, CharacterTaxonomy.Taxonomy] ++
        if serve?() do
          [
            {CharacterTaxonomy.MCPServer,
             transport: :http, port: mcp_port(), host: "0.0.0.0", sse_enabled: true},
            {Bandit, plug: CharacterTaxonomy.Router, port: cms_port()}
          ]
        else
          []
        end

    opts = [strategy: :one_for_one, name: CharacterTaxonomy.Supervisor]
    {:ok, pid} = Supervisor.start_link(children, opts)
    if serve?(), do: CharacterTaxonomy.Taxonomy.hydrate()
    {:ok, pid}
  end

  # The suite calls Taxonomy and Repo directly through its own named
  # Agents, the way WeftspunStudio.FactStoreTest does. Neither
  # listener needs to open a port for that, and a fixed port would
  # collide across parallel CI jobs.
  defp serve?, do: not test_env?()
  defp test_env?, do: Code.ensure_loaded?(Mix) and Mix.env() == :test

  defp mcp_port, do: String.to_integer(System.get_env("MCP_PORT", "4001"))
  defp cms_port, do: String.to_integer(System.get_env("PORT", "8080"))
end
