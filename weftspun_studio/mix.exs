defmodule WeftspunStudio.MixProject do
  use Mix.Project

  @app :weftspun_studio
  @version "0.1.0"

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
      # Tensor work. RFD 0019 first selected EXLA, and XLA publishes no
      # Windows archive. Torchx binds LibTorch, which ships for
      # Windows, macOS, and Linux with a CUDA build for each. Set
      # LIBTORCH_TARGET=cu124 for the NVIDIA build.
      {:nx, "~> 0.13"},
      {:torchx, "~> 0.13"},
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
      # runs each model as its own Cog. RFD 0036 records the packaging.
      {:req, "~> 0.5"},
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

  # Burrito wraps the release into one self-contained binary.
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
      ]
    ]
  end
end
