defmodule WeftspunPopcorn.MixProject do
  use Mix.Project

  def project do
    [
      app: :weftspun_popcorn,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [],
      mod: {WeftspunPopcorn.Application, []}
    ]
  end

  defp deps do
    [
      {:popcorn, "~> 0.3.2"}
    ]
  end

  # `popcorn.cook` compiles this project to an AtomVM bundle. The
  # JavaScript build then wraps that bundle for the webview.
  defp aliases do
    [
      build: ["deps.get", "popcorn.cook", &build_js/1]
    ]
  end

  defp build_js(_) do
    assets = Path.join(File.cwd!(), "assets")

    {_, 0} =
      System.cmd(npm(), ["install"],
        cd: assets,
        into: IO.stream(:stdio, :line),
        stderr_to_stdout: true
      )

    {_, 0} =
      System.cmd(npm(), ["run", "build"],
        cd: assets,
        into: IO.stream(:stdio, :line),
        stderr_to_stdout: true
      )
  end

  defp npm, do: if(match?({:win32, _}, :os.type()), do: "npm.cmd", else: "npm")
end
