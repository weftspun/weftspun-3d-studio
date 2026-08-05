defmodule WeftspunStudio.MixProject do
  use Mix.Project

  @app :weftspun_studio
  @version "0.2.0"

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases(),
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {WeftspunStudio.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Tensor work. RFD 0019 selects EXLA, and nothing else. EXLA
      # compiles Nx.Defn graphs with XLA, and it is the only backend
      # this project builds against.
      #
      # XLA publishes no Windows archive. Develop in the dev container,
      # which runs Linux, and RFD 0056 records it. This box's own
      # Quadlets run Linux too, thus the container matches production.
      {:nx, "~> 0.13"},
      {:exla, "~> 0.13"},
      # The phase algebra behind fact retrieval. One definition shared
      # across the weftspun repositories. RFD 0021 records the move.
      {:hrr, github: "weftspun/elixir-holographic-reduced-representation"},
      # Provisions and runs the local CockroachDB host. It downloads
      # the same V-Sekai 22.1 build that RFD 0020 selects.
      {:cockroach_local, github: "weftspun/cockroach-local"},
      # Single-binary packaging. Needs Zig at build time.
      {:burrito, "~> 1.0"},
      {:jason, "~> 1.4"},
      # HTTP surface. Smallest slice that serves the client.
      {:bandit, "~> 1.5"},
      {:plug, "~> 1.16"},
      # Outbound HTTP. The job routes pass through to Replicate, which
      # runs each model as its own Cog. RFD 0055 keeps that passthrough
      # until this box's own worker answers. RFD 0036 packages the
      # model images that replace it, and it no longer selects Cog.
      {:req, "~> 0.5"},
      # The HTN planner. RFD 0037 models each pipeline as a RECTGTN
      # domain, and priv/domains holds them.
      {:taskweft, github: "taskweft/taskweft", ref: "main"},
      # Persistence. CockroachDB speaks the PostgreSQL wire protocol,
      # so Ecto drives it through Postgrex. RFD 0020 records why.
      {:ecto_sql, "~> 3.12"},
      {:postgrex, "~> 0.19"},
      # Mocks for the API surface the UI consumes.
      {:mox, "~> 1.1", only: :test}
    ]
  end

  # `mix test` prepares a clean database first. CockroachDB holds no
  # per-connection advisory lock, so the migration lock stays off.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end

  # Burrito wraps the release into one self-contained binary, for a
  # host with no Elixir, no Erlang, and no Podman. `weftspun_container`
  # is a plain assembled release with no Burrito step, for the
  # Dockerfile — the image is already the distribution unit there, so
  # wrapping it again just adds a Zig build dependency for nothing.
  # RFD 0058 records both paths.
  defp releases do
    [
      weftspun: [
        steps: [:assemble, &Burrito.wrap/1],
        burrito: [
          targets: [
            linux_x86_64: [os: :linux, cpu: :x86_64],
            linux_aarch64: [os: :linux, cpu: :aarch64]
          ]
        ]
      ],
      weftspun_container: [
        steps: [:assemble]
      ]
    ]
  end
end
