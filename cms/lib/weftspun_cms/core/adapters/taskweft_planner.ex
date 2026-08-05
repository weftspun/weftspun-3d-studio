# SPDX-License-Identifier: MIT

defmodule WeftspunCMS.Core.Adapters.TaskweftPlanner do
  @moduledoc """
  The planner adapter. It calls taskweft.

  taskweft is a mandatory dependency. The pipeline order lives in a
  RECTGTN domain, thus a build without the planner has no pipeline.

  `Taskweft.Compose` folds the documents. The base leads, each stage
  follows, and the problem goes last, because a later document wins.
  """

  @behaviour WeftspunCMS.Core.Ports.Planner

  @impl true
  def plan(base, overlays) when is_binary(base) and is_list(overlays) do
    with {:ok, document} <- compose([base | overlays]),
         {:ok, json} <- Taskweft.plan(document),
         {:ok, envelope} <- decode(json) do
      steps(envelope)
    end
  end

  @impl true
  def replan(base, plan, fail_step) when is_binary(base) and is_list(plan) do
    with {:ok, document} <- compose([base]),
         {:ok, plan_json} <- encode(plan),
         {:ok, json} <- Taskweft.replan(document, plan_json, fail_step),
         {:ok, envelope} <- decode(json) do
      steps(envelope)
    end
  end

  @impl true
  def validate(document) when is_binary(document) do
    case compose([document]) do
      {:ok, _json} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  # ---------- taskweft ----------

  defp compose(documents) do
    Taskweft.Compose.compose_strings(documents, format: "dsl")
  end

  # ---------- shapes ----------

  # `plan` answers with the steps, and `replan` answers with an
  # envelope that holds them. One shape reaches the port.
  defp steps(%{"plan" => plan}) when is_list(plan), do: {:ok, plan}
  defp steps(%{"steps" => steps}) when is_list(steps), do: {:ok, steps}
  defp steps(plan) when is_list(plan), do: {:ok, plan}
  defp steps(other), do: {:error, "planner returned an unknown shape: #{inspect(other)}"}

  defp decode(json) do
    case Jason.decode(json) do
      {:ok, decoded} -> {:ok, decoded}
      {:error, error} -> {:error, "planner returned invalid JSON: #{Exception.message(error)}"}
    end
  end

  defp encode(term) do
    case Jason.encode(term) do
      {:ok, json} -> {:ok, json}
      {:error, error} -> {:error, "cannot encode the plan: #{Exception.message(error)}"}
    end
  end
end
