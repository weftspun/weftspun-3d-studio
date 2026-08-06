# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule WeftspunStudio.Adapters.HttpGallery do
  @moduledoc """
  Driven adapter: fetches the gallery from its own deployed app.

  A plain reverse proxy, and nothing more, the same shape RFD 0019
  already gives `WeftspunStudio.Adapters.ReplicateJobs`. The gallery
  app (RFD 0076) already answers every path this server forwards, at
  the same path, so no rewrite happens here. `decode_body: false`
  keeps Req from touching binary bodies such as the `.wasm` and
  `.usdz` payloads; JSON auto-decoding would corrupt them.
  """

  @behaviour WeftspunStudio.Ports.GallerySource

  @impl true
  def fetch(_state, path) do
    case Req.get(base_url() <> path, decode_body: false) do
      {:ok, %Req.Response{status: 200, body: body, headers: headers}} ->
        {:ok, body, content_type(headers)}

      _ ->
        :error
    end
  end

  defp content_type(headers) do
    case Map.get(headers, "content-type") do
      [value | _] -> value
      _ -> "application/octet-stream"
    end
  end

  defp base_url do
    Application.get_env(:weftspun_studio, :gallery_url, "http://localhost:8090")
  end
end
