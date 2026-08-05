# SPDX-License-Identifier: MIT

defmodule WeftspunCMS.Core.Ports.OwnedAssetSource do
  @moduledoc """
  The port for owned assets.

  Content needs one answer from a chain: which assets may this owner
  use? A trait an owner holds is a trait a picker may offer. That is a
  content availability question, and it is the whole of the port.

  RFD 0023 defines it. The null adapter is the headless case, and it
  answers with empty lists and no chain library.
  """

  @typedoc "An owner address. Opaque here, and never parsed."
  @type address :: String.t()

  @typedoc "What a locked collection or a purchase frees."
  @type unlocked :: %{owned_ids: [String.t()], owned_traits: %{String.t() => [String.t()]}}

  @doc "False when no chain is configured. The headless default."
  @callback enabled?() :: boolean()

  @doc "The collections the deployment knows."
  @callback list_collections() :: {:ok, [map()]} | {:error, String.t()}

  @doc "The trait ids one address holds."
  @callback list_owned_trait_ids(address()) :: {:ok, [String.t()]} | {:error, String.t()}

  @doc """
  The traits a locked collection frees.

  An incomplete query frees nothing, and no adapter rejects. A picker
  that cannot reach a chain shows the locked set, and the page loads.
  """
  @callback list_collection_traits(map()) :: {:ok, unlocked()} | {:error, String.t()}

  @doc "The traits a purchase frees. Same shape as the collection read."
  @callback list_purchased_traits(map()) :: {:ok, unlocked()} | {:error, String.t()}
end
