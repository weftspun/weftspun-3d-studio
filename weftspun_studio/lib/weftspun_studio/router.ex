# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule WeftspunStudio.Router do
  @moduledoc """
  HTTP surface. The smallest slice that serves the client.

  RFD 0019 makes this application an API server in the headless
  content system style. Phase 1 exposes the model catalog only. The
  job routes stay with the client until a later phase.
  """

  use Plug.Router

  plug(:fetch_query_params)
  plug(:match)
  plug(:dispatch)

  get "/api/v1/models" do
    entries =
      case conn.params["feature"] do
        nil -> catalog().list_models(nil)
        feature -> catalog().list_for_feature(nil, feature)
      end

    json(conn, 200, %{models: entries})
  end

  get "/api/v1/facts" do
    facts =
      case conn.params["min_trust"] do
        nil -> catalog().list_facts(nil)
        raw -> catalog().list_facts_above(nil, String.to_float(raw))
      end

    json(conn, 200, %{facts: Enum.map(facts, &encode_fact/1)})
  end

  get "/api/v1/models/features" do
    json(conn, 200, %{features: catalog().list_features(nil)})
  end

  get "/api/v1/health" do
    json(conn, 200, %{status: "ok", version: WeftspunStudio.CLI.version()})
  end

  match _ do
    json(conn, 404, %{error: "not found"})
  end

  defp encode_fact(fact), do: %{fact | updated_at: DateTime.to_iso8601(fact.updated_at)}

  defp json(conn, status, body) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(status, Jason.encode!(body))
  end

  defp catalog do
    Application.get_env(
      :weftspun_studio,
      :catalog_source,
      WeftspunStudio.Adapters.InventoryCatalog
    )
  end
end
