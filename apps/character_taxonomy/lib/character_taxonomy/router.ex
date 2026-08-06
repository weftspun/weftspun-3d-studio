# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule CharacterTaxonomy.Router do
  @moduledoc """
  Headless-CMS HTTP surface, in `WeftspunStudio.Router`'s own style.

  One JSON route serves the taxonomy RFD 0065 builds. The static
  randomizer page is content, not code, so it lives under
  `priv/static/` and this plug only serves the file.
  """

  use Plug.Router

  plug(Plug.Static,
    at: "/",
    from: {:character_taxonomy, "priv/static"},
    only: ~w(index.html app.js)
  )

  plug(:match)
  plug(:dispatch)

  alias CharacterTaxonomy.Taxonomy

  # Plug.Static serves a named file, not a directory index, so "/"
  # needs its own route to the same content.
  get "/" do
    conn
    |> Plug.Conn.put_resp_content_type("text/html")
    |> Plug.Conn.send_file(200, Application.app_dir(:character_taxonomy, "priv/static/index.html"))
  end

  get "/api/v1/traits" do
    json(conn, 200, Taxonomy.snapshot(Taxonomy))
  end

  get "/api/v1/health" do
    json(conn, 200, %{status: "ok", service: "character_taxonomy"})
  end

  match _ do
    json(conn, 404, %{error: "not found"})
  end

  defp json(conn, status, body) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(status, Jason.encode!(body))
  end
end
