# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule WeftspunStudio.Adapters.TaskweftPlanner do
  @moduledoc """
  Planner adapter. It calls taskweft.

  `Taskweft.Compose` folds the documents. The base leads, each stage
  follows, and the problem goes last, because a later document wins.

  taskweft is optional here. It carries a C++ NIF, and the HTTP
  surface must start without it, thus every function answers
  `{:error, :planner_absent}` when the module did not load. RFD 0019
  keeps the inventory commands working with no accelerator, and this
  follows that rule.
  """

  @behaviour WeftspunStudio.Ports.Planner

  @impl true
  def plan(_state, base, overlays) when is_binary(base) and is_list(overlays) do
    with :ok <- loaded(),
         {:ok, document} <- compose([base | overlays]),
         {:ok, json} <- Taskweft.plan(document),
         {:ok, envelope} <- decode(json) do
      steps(envelope)
    end
  end

  @impl true
  def replan(_state, base, plan, fail_step) when is_binary(base) and is_list(plan) do
    with :ok <- loaded(),
         {:ok, document} <- compose([base]),
         {:ok, plan_json} <- encode(plan),
         {:ok, json} <- Taskweft.replan(document, plan_json, fail_step),
         {:ok, envelope} <- decode(json) do
      steps(envelope)
    end
  end

  @impl true
  def validate(_state, document) when is_binary(document) do
    with :ok <- loaded() do
      case compose([document]) do
        {:ok, _json} -> :ok
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp loaded do
    if Code.ensure_loaded?(Taskweft), do: :ok, else: {:error, :planner_absent}
  end

  defp compose(documents) do
    Taskweft.Compose.compose_strings(documents, format: "dsl")
  end

  # `plan` answers with the steps, and `replan` answers with an
  # envelope that holds them. One shape reaches the port.
  defp steps(%{"plan" => plan}) when is_list(plan), do: {:ok, plan}
  defp steps(%{"steps" => steps}) when is_list(steps), do: {:ok, steps}
  defp steps(plan) when is_list(plan), do: {:ok, plan}
  defp steps(other), do: {:error, {:unknown_plan_shape, other}}

  defp decode(json) do
    case Jason.decode(json) do
      {:ok, decoded} -> {:ok, decoded}
      {:error, error} -> {:error, {:invalid_plan_json, Exception.message(error)}}
    end
  end

  defp encode(term) do
    case Jason.encode(term) do
      {:ok, json} -> {:ok, json}
      {:error, error} -> {:error, {:cannot_encode_plan, Exception.message(error)}}
    end
  end
end
