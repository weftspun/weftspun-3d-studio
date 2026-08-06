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
  # RFD 0079: traces every request through this router, reported to
  # AppSignal. Must load before :match/:dispatch so it wraps the
  # whole pipeline, per appsignal_plug's own setup instructions.
  use Appsignal.Plug

  # RFD 0075's GitHub login needs a session to hold the CSRF `state`
  # value across the redirect to GitHub and back, and to hold the
  # logged-in user afterward. A signed cookie, no new database table,
  # no new process. Plug.Router sets no secret_key_base on its own,
  # unlike a Phoenix endpoint, so :put_secret_key_base sets it from
  # the SECRET_KEY_BASE Fly secret before Plug.Session runs.
  plug(:put_secret_key_base)

  plug(Plug.Session,
    store: :cookie,
    key: "_weftspun_studio_session",
    signing_salt: "rfd0075_github_login"
  )

  plug(:fetch_session)
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
  #
  # RFD 0076 moves the gallery's bytes out to its own deployed app.
  # This server forwards, through the GallerySource port, at the
  # same path the gallery app itself answers, no rewrite.
  get "/" do
    proxy_gallery(conn, "/gallery/index.html")
  end

  # Plug.Router normalizes a trailing slash away when it splits
  # path_info, so "/gallery" and "/gallery/" already match the same
  # clause; a second, separate "/gallery/" clause here would be
  # unreachable dead code, confirmed by the compiler's own "cannot
  # match" warning.
  get "/gallery" do
    proxy_gallery(conn, "/gallery/index.html")
  end

  get "/gallery/*rest" do
    proxy_gallery(conn, "/gallery/" <> Enum.join(rest, "/"))
  end

  # usd-viewer's WASM build uses `src` as both the fetch URL and a
  # raw path inside its own virtual filesystem, and that filesystem
  # does not create intermediate directories. Any src with a "/" in
  # it fails there with "No such file or directory", confirmed live
  # with Playwright, even though the HTTP fetch itself succeeds. A
  # flat filename, at a flat route, sidesteps it entirely.
  get "/sample_billboard.usdz" do
    proxy_gallery(conn, "/gallery/usd/sample_billboard.usdz")
  end

  # ---------- RFD 0075: GitHub login, gated on weftspun membership ----------

  # A random, per-attempt value, checked again in the callback below,
  # so a forged callback request cannot forge a login too, the
  # standard OAuth CSRF defense.
  get "/auth/github/login" do
    state = :crypto.strong_rand_bytes(24) |> Base.url_encode64(padding: false)

    query =
      URI.encode_query(%{
        "client_id" => System.fetch_env!("GITHUB_OAUTH_CLIENT_ID"),
        "redirect_uri" => github_callback_url(),
        "scope" => "read:org",
        "state" => state
      })

    conn
    |> Plug.Conn.put_session(:oauth_state, state)
    |> Plug.Conn.put_resp_header("location", "https://github.com/login/oauth/authorize?" <> query)
    |> Plug.Conn.send_resp(302, "")
  end

  get "/auth/github/callback" do
    expected_state = Plug.Conn.get_session(conn, :oauth_state)
    code = conn.params["code"]
    state = conn.params["state"]

    cond do
      is_nil(code) -> json(conn, 400, %{error: "missing code"})
      is_nil(expected_state) or state != expected_state -> json(conn, 400, %{error: "state mismatch"})
      true -> handle_github_callback(conn, code)
    end
  end

  # One small protected route, demonstrating the gate works. The
  # upload-admin routes this login exists for do not exist yet, RFD
  # 0075's own DETAILS.md names that as open work, not built here.
  get "/api/v1/admin/whoami" do
    case Plug.Conn.get_session(conn, :github_user) do
      nil -> json(conn, 401, %{error: "not logged in"})
      user -> json(conn, 200, %{user: user, org: "weftspun"})
    end
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

  defp put_secret_key_base(conn, _opts) do
    %{conn | secret_key_base: System.fetch_env!("SECRET_KEY_BASE")}
  end

  defp github_callback_url do
    System.get_env(
      "GITHUB_OAUTH_CALLBACK_URL",
      "https://weftspun-studio.fly.dev/auth/github/callback"
    )
  end

  # The three real calls: trade the one-time code for a token, read
  # whose token it is, then check that person against the org roster.
  # A 204 from GitHub's own membership endpoint means a real member; a
  # 404 means it does not, per GitHub's own documented contract for
  # that route. Anything else is a real, reported failure, not a
  # silent one.
  defp handle_github_callback(conn, code) do
    with {:ok, token} <- exchange_code_for_token(code),
         {:ok, username} <- fetch_github_username(token),
         :ok <- verify_org_membership(token, username) do
      conn
      |> Plug.Conn.put_session(:github_user, username)
      |> Plug.Conn.delete_session(:oauth_state)
      |> json(200, %{status: "ok", user: username, org: "weftspun"})
    else
      {:error, :not_a_member, username} ->
        json(conn, 403, %{error: "not a weftspun member", user: username})

      {:error, reason} ->
        json(conn, 502, %{error: "github oauth failed", reason: inspect(reason)})
    end
  end

  defp exchange_code_for_token(code) do
    case Req.post("https://github.com/login/oauth/access_token",
           headers: [{"accept", "application/json"}],
           form: [
             client_id: System.fetch_env!("GITHUB_OAUTH_CLIENT_ID"),
             client_secret: System.fetch_env!("GITHUB_OAUTH_CLIENT_SECRET"),
             code: code,
             redirect_uri: github_callback_url()
           ]
         ) do
      {:ok, %{status: 200, body: %{"access_token" => token}}} -> {:ok, token}
      {:ok, %{body: body}} -> {:error, {:no_token, body}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp fetch_github_username(token) do
    case Req.get("https://api.github.com/user", headers: github_api_headers(token)) do
      {:ok, %{status: 200, body: %{"login" => login}}} -> {:ok, login}
      {:ok, %{status: status, body: body}} -> {:error, {:user_lookup_failed, status, body}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp verify_org_membership(token, username) do
    url = "https://api.github.com/orgs/weftspun/members/#{username}"

    case Req.get(url, headers: github_api_headers(token)) do
      {:ok, %{status: 204}} -> :ok
      {:ok, %{status: 404}} -> {:error, :not_a_member, username}
      {:ok, %{status: status}} -> {:error, {:membership_check_failed, status}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp github_api_headers(token) do
    [{"authorization", "Bearer " <> token}, {"user-agent", "weftspun-studio"}]
  end

  # RFD 0073's billboard gallery, the usd-viewer web component's WASM
  # build, needs SharedArrayBuffer, thus COEP/COOP on every response
  # this proxies from the gallery app. No other route sets these, so
  # nothing else is affected.
  defp proxy_gallery(conn, path) do
    case gallery_source().fetch(nil, path) do
      {:ok, body, content_type} ->
        # put_resp_header, not put_resp_content_type: the latter
        # appends its own "; charset=utf-8" unconditionally, wrong
        # for a binary type such as "application/wasm", and doubled
        # up for a text type the gallery app already sent a charset
        # on.
        conn
        |> Plug.Conn.put_resp_header("cross-origin-embedder-policy", "require-corp")
        |> Plug.Conn.put_resp_header("cross-origin-opener-policy", "same-origin")
        |> Plug.Conn.put_resp_header("content-type", content_type)
        |> Plug.Conn.send_resp(200, body)

      :error ->
        json(conn, 404, %{error: "not found"})
    end
  end

  defp gallery_source do
    Application.get_env(:weftspun_studio, :gallery_source, WeftspunStudio.Adapters.HttpGallery)
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
