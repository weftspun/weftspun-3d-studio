# SPDX-License-Identifier: MIT

defmodule WeftspunCMS.Core.Ports.AssetStore do
  @moduledoc """
  The port for stored assets.

  RFD 0053 makes OpenUSD the internal format. A stage writes a layer,
  and the layer below stays intact. This port therefore stores layers,
  and not whole assets.

  `put_layer/3` takes the stage that wrote it. A caller may then mute
  one stage and read what came before.
  """

  @type asset_id :: String.t()
  @type stage :: String.t()

  @doc "Stores one layer for an asset, written by one stage."
  @callback put_layer(asset_id(), stage(), binary()) :: {:ok, String.t()} | {:error, String.t()}

  @doc "Reads one stage's layer."
  @callback get_layer(asset_id(), stage()) :: {:ok, binary()} | {:error, :not_found}

  @doc "The stages that wrote a layer for this asset, in write order."
  @callback list_stages(asset_id()) :: {:ok, [stage()]} | {:error, String.t()}

  @doc """
  Composes the stack into one transmission file.

  RFD 0053 keeps USD inside and sends glTF, VRM, or KHR avatar out. The
  format names which.
  """
  @callback compose(asset_id(), String.t()) :: {:ok, binary()} | {:error, String.t()}
end
