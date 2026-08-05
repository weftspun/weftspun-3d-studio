# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule WeftspunStudio.Pipeline do
  @moduledoc """
  Which planning documents a pipeline composes, and in what order.

  Order is the whole rule. Compose folds left to right and a later
  document wins, thus the base goes first and the problem goes last. A
  stage document that came before the base would lose its overrides.

  The documents live in `priv/domains` and `priv/problems`. They are
  the one part of the pipeline that is not code, and RFD 0037 records
  why they are Elixir DSL rather than JSON.
  """

  @base "content_lifecycle"

  @pipelines %{
    # The smallest useful pipeline. It proves the base plans alone.
    content_only: %{stages: [], problem: nil},
    mesh: %{stages: ["stage_mesh"], problem: nil},
    avatar: %{stages: ["stage_mesh", "stage_rig"], problem: "avatar"}
  }

  @type name :: atom()

  @doc "The pipelines this deployment knows."
  @spec names() :: [name()]
  def names, do: @pipelines |> Map.keys() |> Enum.sort()

  @doc "The base every pipeline composes over."
  @spec base() :: String.t()
  def base, do: @base

  @doc """
  The document names for one pipeline, in compose order.

  Returns `{:error, :unknown_pipeline}` rather than raising. A name
  arrives from an HTTP request, and a bad request is not a programmer
  error.
  """
  @spec documents(name()) ::
          {:ok, %{domains: [String.t()], problem: String.t() | nil}}
          | {:error, :unknown_pipeline}
  def documents(name) do
    case Map.fetch(@pipelines, name) do
      {:ok, %{stages: stages, problem: problem}} ->
        {:ok, %{domains: [@base | stages], problem: problem}}

      :error ->
        {:error, :unknown_pipeline}
    end
  end

  @doc """
  Parses a pipeline name that arrived as text.

  `String.to_existing_atom/1` and not `String.to_atom/1`. An HTTP
  caller must not create atoms, because the table never shrinks.
  """
  @spec parse(String.t()) :: {:ok, name()} | {:error, :unknown_pipeline}
  def parse(text) when is_binary(text) do
    name = String.to_existing_atom(text)
    if Map.has_key?(@pipelines, name), do: {:ok, name}, else: {:error, :unknown_pipeline}
  rescue
    ArgumentError -> {:error, :unknown_pipeline}
  end

  @doc """
  Reads the documents for a pipeline, in compose order.

  The base leads and the problem trails.
  """
  @spec load(name()) ::
          {:ok, %{base: String.t(), overlays: [String.t()]}} | {:error, term()}
  def load(pipeline) do
    with {:ok, %{domains: domains, problem: problem}} <- documents(pipeline),
         {:ok, sources} <- read_all(Enum.map(domains, &domain_path/1)),
         {:ok, problem_sources} <- read_problem(problem) do
      [base | stage_sources] = sources
      {:ok, %{base: base, overlays: stage_sources ++ problem_sources}}
    end
  end

  @doc "The absolute path of one domain document."
  @spec domain_path(String.t()) :: String.t()
  def domain_path(name), do: Path.join([priv(), "domains", name <> ".ex"])

  @doc "The absolute path of one problem document."
  @spec problem_path(String.t()) :: String.t()
  def problem_path(name), do: Path.join([priv(), "problems", name <> ".ex"])

  defp read_problem(nil), do: {:ok, []}
  defp read_problem(name), do: read_all([problem_path(name)])

  defp read_all(paths) do
    Enum.reduce_while(paths, {:ok, []}, fn path, {:ok, acc} ->
      case File.read(path) do
        {:ok, source} -> {:cont, {:ok, acc ++ [source]}}
        {:error, reason} -> {:halt, {:error, {:cannot_read, path, reason}}}
      end
    end)
  end

  defp priv, do: Application.app_dir(:weftspun_studio, "priv")
end
