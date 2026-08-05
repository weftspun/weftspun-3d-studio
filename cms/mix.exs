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

      # The planner. Mandatory. The pipeline order lives in a RECTGTN
      # domain, thus a build without taskweft has no pipeline.
      #
      # It tracks the git ref, and not the Hex release. Composition
      # landed after 0.4.0, and RFD 0054 records that this project
      # needs it.
      {:taskweft, github: "taskweft/taskweft", branch: "goal-eq-literal"}
    ]
  end
end
