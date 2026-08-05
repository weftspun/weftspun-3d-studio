# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule WeftspunStudio.Adapters.ReplicateJobs do
  @moduledoc """
  Job adapter for Replicate. A passthrough, and nothing more.

  RFD 0019 gave the job ports a later phase, and the port doc named
  the DGX backend. There is no DGX. Replicate runs each model as its
  own Cog, thus this adapter forwards and translates. RFD 0055 keeps
  this passthrough until one vast.ai worker answers.

  It holds no queue and no state. Replicate owns the prediction, and
  this module maps two vocabularies:

  - a catalog model id becomes a Replicate model owner and name
  - a Replicate status becomes an RFD 0003 status

  A passthrough is the right shape here because Replicate already
  queues, retries, and reports progress. A second queue in front of it
  would hold a copy of that state and drift from it.
  """

  @behaviour WeftspunStudio.Ports.JobSink
  @behaviour WeftspunStudio.Ports.JobSource

  @base "https://api.replicate.com/v1"

  # Replicate reports six statuses. RFD 0003 names four. `starting`
  # and `processing` both mean the work is not done, and the client
  # draws them the same way.
  @status %{
    "starting" => :queued,
    "processing" => :running,
    "succeeded" => :completed,
    "failed" => :failed,
    "canceled" => :failed
  }

  # ---------- JobSink ----------

  @impl WeftspunStudio.Ports.JobSink
  # Replicate stores no feature on a prediction. The argument stays in
  # the port because RFD 0003 job records carry it, and the caller that
  # keeps those records needs it.
  def create_job(state, _feature, model, params) do
    with {:ok, target} <- resolve(model),
         {:ok, body} <- post(state, "/predictions", %{version: target, input: params}) do
      {:ok, body["id"]}
    end
  end

  @impl WeftspunStudio.Ports.JobSink
  def cancel_job(state, job_id) do
    case post(state, "/predictions/#{job_id}/cancel", %{}) do
      {:ok, _body} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  # ---------- JobSource ----------

  @impl WeftspunStudio.Ports.JobSource
  def fetch_job(state, job_id) do
    case get(state, "/predictions/#{job_id}") do
      {:ok, body} -> {:ok, to_job(body)}
      {:error, :not_found} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl WeftspunStudio.Ports.JobSource
  def list_jobs(state, limit) do
    case get(state, "/predictions") do
      {:ok, body} ->
        jobs =
          body
          |> Map.get("results", [])
          |> Enum.map(&to_job/1)
          |> take(limit)

        {:ok, jobs}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # ---------- translation ----------

  @doc """
  Maps a catalog model id to the Replicate model it runs on.

  The map is config, and not code. A model moves owner without a
  release, thus a hard-coded name would need one.
  """
  @spec resolve(String.t()) :: {:ok, String.t()} | {:error, {:unknown_model, String.t()}}
  def resolve(model_id) do
    case Map.fetch(model_map(), model_id) do
      {:ok, target} -> {:ok, target}
      :error -> {:error, {:unknown_model, model_id}}
    end
  end

  defp model_map do
    Application.get_env(:weftspun_studio, :replicate_models, %{})
  end

  # A Replicate prediction carries no feature and no model id of ours.
  # It carries the version it ran. The client needs our vocabulary,
  # thus the reverse lookup runs here.
  defp to_job(body) do
    %{
      id: body["id"],
      status: Map.get(@status, body["status"], :queued),
      feature: body["feature"] || "",
      model: reverse(body["version"]),
      progress: progress(body),
      result: body["output"],
      error: body["error"]
    }
  end

  defp reverse(version) do
    model_map()
    |> Enum.find_value("", fn {id, target} -> if target == version, do: id end)
  end

  # Replicate reports no percentage. A finished job is 1.0, and an
  # unfinished one is 0.0. A fabricated middle value would read as
  # progress the backend never gave.
  defp progress(%{"status" => "succeeded"}), do: 1.0
  defp progress(_body), do: 0.0

  defp take(jobs, nil), do: jobs
  defp take(jobs, limit) when is_integer(limit), do: Enum.take(jobs, limit)

  # ---------- transport ----------

  defp get(state, path), do: request(state, :get, path, nil)
  defp post(state, path, body), do: request(state, :post, path, body)

  defp request(state, method, path, body) do
    case token(state) do
      nil ->
        {:error, :no_replicate_token}

      token ->
        [
          method: method,
          url: @base <> path,
          headers: [{"authorization", "Bearer " <> token}],
          json: body,
          receive_timeout: 30_000
        ]
        |> Keyword.reject(fn {_key, value} -> is_nil(value) end)
        |> Req.request()
        |> handle()
    end
  end

  defp handle({:ok, %{status: status, body: body}}) when status in 200..299, do: {:ok, body}
  defp handle({:ok, %{status: 404}}), do: {:error, :not_found}

  defp handle({:ok, %{status: status, body: body}}),
    do: {:error, {:replicate_error, status, detail(body)}}

  defp handle({:error, reason}), do: {:error, reason}

  defp detail(%{"detail" => detail}), do: detail
  defp detail(body), do: body

  # The state argument may carry a token, which is what a test uses.
  # Otherwise it comes from config.
  defp token(%{token: token}) when is_binary(token), do: token

  defp token(_state) do
    Application.get_env(:weftspun_studio, :replicate_token) ||
      System.get_env("REPLICATE_API_TOKEN")
  end
end
