# SPDX-License-Identifier: MIT

defmodule WeftspunCMS.Core.Adapters.NullOwnedAssetSource do
  @moduledoc """
  The headless owned-asset adapter. It reaches no chain.

  This is the default. RFD 0023 records the reason: a content system
  serves with no wallet, no network, and no chain library.

  Every read answers with the empty shape, and none of them rejects. A
  picker that cannot reach a chain shows the locked set, and the page
  loads.
  """

  @behaviour WeftspunCMS.Core.Ports.OwnedAssetSource

  @impl true
  def enabled?, do: false

  @impl true
  def list_collections, do: {:ok, []}

  @impl true
  def list_owned_trait_ids(_address), do: {:ok, []}

  @impl true
  def list_collection_traits(_query), do: {:ok, empty()}

  @impl true
  def list_purchased_traits(_query), do: {:ok, empty()}

  # A fresh map each call. A shared literal would let one caller's
  # change reach another, and the client carried that fault once.
  defp empty, do: %{owned_ids: [], owned_traits: %{}}
end
