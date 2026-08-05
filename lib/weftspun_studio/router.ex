# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule WeftspunStudio.Router do
  @moduledoc """
  HTTP surface. The smallest slice that serves the client.

  RFD 0019 makes this application an API server in the headless
  content system style. Phase 1 exposed the model catalog only.

  The job routes pass through to Replicate, which runs each model as
  its own Cog. This server holds no queue. Replicate already queues,
  retries, and reports, thus a second queue here would keep a copy of
  that state and drift from it.
  """

  use Plug.Router

  # RFD 0073's billboard gallery, the usd-viewer web component's
  # WASM build needs SharedArrayBuffer, thus COEP/COOP on this one
  # path. No other route sets these, so nothing else is affected.
  plug(:coep_for_gallery)
  plug(Plug.Static, at: "/gallery", from: {:weftspun_studio, "priv/static/gallery"})

  plug(:fetch_query_params)
  plug(:match)

  # A job create carries JSON, and the catalog routes do not. Parsing
  # runs after match so a GET pays nothing for it.
  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

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

  get "/api/v1/facts/search" do
    query = conn.params["q"] || ""
    limit = String.to_integer(conn.params["limit"] || "5")
    min_trust = String.to_float(conn.params["min_trust"] || "0.0")

    results =
      WeftspunStudio.FactStore.search(query, limit: limit, min_trust: min_trust)
      |> Enum.map(fn {fact, score} ->
        fact |> Map.drop([:hrr_vector]) |> encode_fact() |> Map.put(:score, score)
      end)

    json(conn, 200, %{query: query, results: results})
  end

  get "/api/v1/models/features" do
    json(conn, 200, %{features: catalog().list_features(nil)})
  end

  get "/api/v1/health" do
    json(conn, 200, %{status: "ok", version: WeftspunStudio.CLI.version()})
  end

  # RFD 0062's full browser client is not wired in yet, but the RFD
  # 0073 billboard gallery already is. Sketchfab and Fab both put
  # the 3D preview at the root, not under a sub-path, so this does
  # the same rather than answer "/" with a bare status stub.
  get "/" do
    send_gallery_index(conn)
  end

  # Plug.Static answers /gallery/index.html and every asset under it
  # correctly, but it does not resolve a bare directory request to
  # index.html, the way a static file server usually does. These two
  # routes cover that gap for the RFD 0073 gallery.
  get "/gallery" do
    send_gallery_index(conn)
  end

  # usd-viewer's WASM build uses `src` as both the fetch URL and a
  # raw path inside its own virtual filesystem, and that filesystem
  # does not create intermediate directories. Any src with a "/" in
  # it fails there with "No such file or directory", confirmed live
  # with Playwright, even though the HTTP fetch itself succeeds. A
  # flat filename, at a flat route, sidesteps it entirely.
  get "/sample_billboard.usdz" do
    path = Application.app_dir(:weftspun_studio, "priv/static/gallery/usd/sample_billboard.usdz")
    conn |> Plug.Conn.put_resp_content_type("model/vnd.usdz+zip") |> Plug.Conn.send_file(200, path)
  end

  get "/gallery/" do
    send_gallery_index(conn)
  end

  # ---------- jobs, passed through to Replicate ----------

  post "/api/v1/jobs" do
    %{"feature" => feature, "model" => model} = conn.body_params
    params = conn.body_params["params"] || %{}

    case job_sink().create_job(nil, feature, model, params) do
      {:ok, id} -> json(conn, 202, %{job_id: id, status: "queued"})
      {:error, reason} -> error(conn, reason)
    end
  end

  get "/api/v1/jobs/:id" do
    case job_source().fetch_job(nil, id) do
      {:ok, job} -> json(conn, 200, job)
      {:error, reason} -> error(conn, reason)
    end
  end

  get "/api/v1/jobs" do
    limit =
      case conn.params["limit"] do
        nil -> nil
        raw -> String.to_integer(raw)
      end

    case job_source().list_jobs(nil, limit) do
      {:ok, jobs} -> json(conn, 200, %{jobs: jobs})
      {:error, reason} -> error(conn, reason)
    end
  end

  post "/api/v1/jobs/:id/cancel" do
    case job_sink().cancel_job(nil, id) do
      :ok -> json(conn, 200, %{job_id: id, status: "canceled"})
      {:error, reason} -> error(conn, reason)
    end
  end

  # ---------- pipelines ----------

  get "/api/v1/pipelines" do
    json(conn, 200, %{pipelines: WeftspunStudio.Pipeline.names()})
  end

  # Solves a pipeline into its ordered steps, and runs nothing. A
  # caller sees what the plan is before it pays for the models.
  get "/api/v1/pipelines/:name/plan" do
    with {:ok, pipeline} <- WeftspunStudio.Pipeline.parse(name),
         {:ok, %{base: base, overlays: overlays}} <- WeftspunStudio.Pipeline.load(pipeline),
         {:ok, steps} <- planner().plan(nil, base, overlays) do
      json(conn, 200, %{pipeline: name, steps: steps, step_count: length(steps)})
    else
      {:error, reason} -> error(conn, reason)
    end
  end

  match _ do
    json(conn, 404, %{error: "not found"})
  end

  # A reason from the port becomes a status a client can act on. An
  # unknown model is the caller's fault, and a missing token is this
  # server's fault. One 500 for both would send a client to retry a
  # request that can never work.
  defp error(conn, :not_found), do: json(conn, 404, %{error: "not found"})

  defp error(conn, :unknown_pipeline), do: json(conn, 404, %{error: "unknown pipeline"})

  # The planner is optional, thus its absence is this server's state
  # and not the caller's fault.
  defp error(conn, :planner_absent),
    do: json(conn, 503, %{error: "the planner did not build"})

  defp error(conn, {:cannot_read, path, reason}),
    do:
      json(conn, 500, %{
        error: "cannot read a planning document",
        path: path,
        reason: inspect(reason)
      })

  defp error(conn, {:unknown_model, id}),
    do: json(conn, 400, %{error: "unknown model", model: id})

  defp error(conn, :no_replicate_token),
    do: json(conn, 503, %{error: "no replicate token is configured"})

  defp error(conn, {:replicate_error, status, detail}),
    do:
      json(conn, 502, %{error: "replicate rejected the request", status: status, detail: detail})

  defp error(conn, reason), do: json(conn, 500, %{error: inspect(reason)})

  defp encode_fact(fact), do: %{fact | updated_at: DateTime.to_iso8601(fact.updated_at)}

  defp send_gallery_index(conn) do
    path = Application.app_dir(:weftspun_studio, "priv/static/gallery/index.html")

    conn
    |> Plug.Conn.put_resp_header("cross-origin-embedder-policy", "require-corp")
    |> Plug.Conn.put_resp_header("cross-origin-opener-policy", "same-origin")
    |> Plug.Conn.put_resp_content_type("text/html")
    |> Plug.Conn.send_file(200, path)
  end

  defp coep_for_gallery(conn, _opts) do
    if conn.path_info |> List.first() == "gallery" do
      conn
      |> Plug.Conn.put_resp_header("cross-origin-embedder-policy", "require-corp")
      |> Plug.Conn.put_resp_header("cross-origin-opener-policy", "same-origin")
    else
      conn
    end
  end

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

  defp job_sink do
    Application.get_env(:weftspun_studio, :job_sink, WeftspunStudio.Adapters.ReplicateJobs)
  end

  defp job_source do
    Application.get_env(:weftspun_studio, :job_source, WeftspunStudio.Adapters.ReplicateJobs)
  end

  defp planner do
    Application.get_env(:weftspun_studio, :planner, WeftspunStudio.Adapters.TaskweftPlanner)
  end
end
