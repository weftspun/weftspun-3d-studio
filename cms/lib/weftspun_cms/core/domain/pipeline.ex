# SPDX-License-Identifier: MIT

defmodule WeftspunCMS.Core.Domain.Pipeline do
  @moduledoc """
  Which documents a pipeline composes, and in what order.

  Pure. It names files and states an order. It reads nothing, thus a
  test needs no disk. `WeftspunCMS.Planning.Loader` does the reading.

  Order is the whole rule. Compose folds left to right and a later
  document wins, thus the base goes first and the problem goes last.
  A stage document that came before the base would lose its overrides.
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
  The documents for one pipeline, in compose order.

  Returns `{:error, :unknown_pipeline}` rather than raising. A pipeline
  name may arrive from an API request, and a bad request is not a
  programmer error.
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
  True when a pipeline overrides a stage another one also has.

  A shared stage is the reason to compose. Two pipelines that both make
  a mesh name the same document, and no copy drifts.
  """
  @spec shares_stage?(name(), name()) :: boolean()
  def shares_stage?(left, right) do
    with {:ok, %{domains: left_docs}} <- documents(left),
         {:ok, %{domains: right_docs}} <- documents(right) do
      shared = MapSet.intersection(MapSet.new(left_docs), MapSet.new(right_docs))
      MapSet.size(MapSet.delete(shared, @base)) > 0
    else
      _error -> false
    end
  end
end
