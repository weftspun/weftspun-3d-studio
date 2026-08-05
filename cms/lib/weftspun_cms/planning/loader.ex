# SPDX-License-Identifier: MIT

defmodule WeftspunCMS.Planning.Loader do
  @moduledoc """
  Reads the planning documents from `priv/`.

  This is the one place that touches the disk for a domain. It is not a
  port, because the documents ship with the release and never vary by
  deployment.

  The documents are the one thing the suite does not mock. RFD 0054
  records why: a mocked domain proves nothing about the pipeline, and
  the domains are the pipeline.
  """

  alias WeftspunCMS.Core.Domain.Pipeline

  @doc "The absolute path of one domain document."
  @spec domain_path(String.t()) :: String.t()
  def domain_path(name), do: Path.join([priv(), "domains", name <> ".ex"])

  @doc "The absolute path of one problem document."
  @spec problem_path(String.t()) :: String.t()
  def problem_path(name), do: Path.join([priv(), "problems", name <> ".ex"])

  @doc """
  Reads the documents for a pipeline, in compose order.

  The base leads and the problem trails, because compose folds left to
  right and a later document wins.
  """
  @spec load(Pipeline.name()) ::
          {:ok, %{base: String.t(), overlays: [String.t()]}} | {:error, term()}
  def load(pipeline) do
    with {:ok, %{domains: domains, problem: problem}} <- Pipeline.documents(pipeline),
         {:ok, sources} <- read_all(Enum.map(domains, &domain_path/1)),
         {:ok, problem_sources} <- read_problem(problem) do
      [base | stage_sources] = sources
      {:ok, %{base: base, overlays: stage_sources ++ problem_sources}}
    end
  end

  defp read_problem(nil), do: {:ok, []}

  defp read_problem(name) do
    case read_all([problem_path(name)]) do
      {:ok, sources} -> {:ok, sources}
      {:error, reason} -> {:error, reason}
    end
  end

  defp read_all(paths) do
    Enum.reduce_while(paths, {:ok, []}, fn path, {:ok, acc} ->
      case File.read(path) do
        {:ok, source} -> {:cont, {:ok, acc ++ [source]}}
        {:error, reason} -> {:halt, {:error, {:cannot_read, path, reason}}}
      end
    end)
  end

  defp priv do
    case :code.priv_dir(:weftspun_cms) do
      {:error, :bad_name} -> Path.expand("../../../priv", __DIR__)
      dir -> to_string(dir)
    end
  end
end
