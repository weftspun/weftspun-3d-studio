# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule WeftspunStudio.Ports.GallerySource do
  @moduledoc """
  Driven source port: read the RFD 0073 gallery inbound.

  RFD 0076 moves `usd_viewer_app` out to its own deployed app, the
  way `character_taxonomy/` already deploys apart from this one.
  This server no longer holds the gallery's bytes on disk; whatever
  implements this contract fetches them across the wire instead. An
  HTTP adapter reaches the deployed gallery in production and in
  dev; a Mox double stands in for tests.
  """

  @type state :: term()

  @doc "The gallery's own response to one request path, such as `/gallery/index.html`."
  @callback fetch(state(), path :: String.t()) ::
              {:ok, body :: binary(), content_type :: String.t()} | :error
end
