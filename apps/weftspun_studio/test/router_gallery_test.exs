# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule WeftspunStudio.RouterGalleryTest do
  @moduledoc """
  RFD 0076: the gallery's bytes come from its own deployed app now,
  through the GallerySource port. These tests pin the proxy contract
  with Mox; no real usd_viewer_app process runs for them.
  """

  use ExUnit.Case, async: true
  use Plug.Test
  import Mox

  alias WeftspunStudio.{GallerySourceMock, Router}

  setup :verify_on_exit!

  setup do
    Application.put_env(:weftspun_studio, :gallery_source, GallerySourceMock)
    on_exit(fn -> Application.delete_env(:weftspun_studio, :gallery_source) end)
  end

  defp call(conn), do: Router.call(conn, Router.init([]))

  test "GET / forwards to /gallery/index.html and sets the COEP/COOP headers" do
    GallerySourceMock
    |> expect(:fetch, fn nil, "/gallery/index.html" ->
      {:ok, "<html></html>", "text/html; charset=utf-8"}
    end)

    conn = call(conn(:get, "/"))

    assert conn.status == 200
    assert conn.resp_body == "<html></html>"
    assert get_resp_header(conn, "content-type") == ["text/html; charset=utf-8"]
    assert get_resp_header(conn, "cross-origin-embedder-policy") == ["require-corp"]
    assert get_resp_header(conn, "cross-origin-opener-policy") == ["same-origin"]
  end

  test "GET /gallery forwards to /gallery/index.html" do
    expect(GallerySourceMock, :fetch, fn nil, "/gallery/index.html" ->
      {:ok, "<html></html>", "text/html; charset=utf-8"}
    end)

    assert call(conn(:get, "/gallery")).status == 200
  end

  test "GET /gallery/vendor/usd-viewer/include.js forwards the full nested path" do
    expect(GallerySourceMock, :fetch, fn nil, "/gallery/vendor/usd-viewer/include.js" ->
      {:ok, "export {};", "text/javascript; charset=utf-8"}
    end)

    conn = call(conn(:get, "/gallery/vendor/usd-viewer/include.js"))
    assert conn.status == 200
    assert conn.resp_body == "export {};"
  end

  test "GET /sample_billboard.usdz forwards to the gallery's own flat usdz route" do
    expect(GallerySourceMock, :fetch, fn nil, "/gallery/usd/sample_billboard.usdz" ->
      {:ok, "PK\0\0", "model/vnd.usdz+zip"}
    end)

    conn = call(conn(:get, "/sample_billboard.usdz"))
    assert conn.status == 200
    assert get_resp_header(conn, "content-type") == ["model/vnd.usdz+zip"]
  end

  test "a gallery app error becomes a 404 JSON, matching every other unknown route" do
    expect(GallerySourceMock, :fetch, fn nil, "/gallery/index.html" -> :error end)

    conn = call(conn(:get, "/"))
    assert conn.status == 404
    assert Jason.decode!(conn.resp_body) == %{"error" => "not found"}
  end
end
