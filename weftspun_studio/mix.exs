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
      # Tensor work. RFD 0019 selects EXLA on CUDA. Build with
      # XLA_TARGET=cuda12 to get the NVIDIA accelerated client.
      {:nx, "~> 0.13"},
      {:exla, "~> 0.13"},
      # Single-binary packaging. Needs Zig at build time.
      {:burrito, "~> 1.0"},
      {:jason, "~> 1.4"}
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
