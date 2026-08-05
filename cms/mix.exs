defmodule WeftspunCMS.MixProject do
  use Mix.Project

  def project do
    [
      app: :weftspun_cms,
      version: "0.1.0",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [summary: [threshold: 0]]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:mox, "~> 1.1", only: :test},

      # The planner. It is optional on purpose: it carries a C++ NIF,
      # and the suite mocks every port, thus a test run needs no NIF.
      # RFD 0054 records that choice.
      {:taskweft,
       github: "taskweft/taskweft", ref: "main", optional: true, runtime: false, only: [:dev, :prod]}
    ]
  end
end
