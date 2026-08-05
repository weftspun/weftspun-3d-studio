defmodule CharacterTaxonomy.MixProject do
  use Mix.Project

  @version "0.1.0"

  # RFD 0065 implements its taxonomy here, as its own Fly.io app, and
  # not as a route inside weftspun_studio. taskweft/taskweft runs the
  # same way: one small Elixir service, its own MCP server, its own
  # domain. RFD 0037 cites that instance. This is a second one, over
  # the character_concept_generator domain instead of a general one.
  def project do
    [
      app: :character_taxonomy,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {CharacterTaxonomy.Application, []}
    ]
  end

  defp deps do
    [
      # The phase algebra RFD 0021 shares across the weftspun
      # repositories. RFD 0065 calls HRR.Cleanup from here, inside
      # taskweft's own generation tooling, and not from
      # WeftspunStudio.FactVector.
      {:hrr, github: "weftspun/elixir-holographic-reduced-representation"},
      # The DSL that reads priv/domains/character_concept_generator.ex,
      # and the planner the plan tool below calls.
      {:taskweft, github: "taskweft/taskweft", ref: "main"},
      # The MCP server framework taskweft's own server.ex uses. RFD
      # 0037 cites taskweft-mcp.fly.dev/mcp as the existing instance.
      {:ex_mcp, "~> 1.0.0-rc"},
      # The headless-CMS JSON route and the static randomizer page.
      {:bandit, "~> 1.5"},
      {:plug, "~> 1.16"},
      {:jason, "~> 1.4"},
      # Persistence. The taxonomy must survive a restart and a
      # redeploy, so it is not Agent state alone. CockroachDB is the
      # database weftspun_studio already runs, per RFD 0020.
      {:cockroach_local, github: "weftspun/cockroach-local"},
      {:ecto_sql, "~> 3.12"},
      {:postgrex, "~> 0.19"}
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end

  defp releases do
    [
      character_taxonomy: [steps: [:assemble]]
    ]
  end
end
