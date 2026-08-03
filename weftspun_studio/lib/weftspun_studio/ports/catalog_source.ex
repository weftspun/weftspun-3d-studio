# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule WeftspunStudio.Ports.CatalogSource do
  @moduledoc """
  Driven source port: read the model catalog inbound.

  The task sidebar picks a model per task type. Whatever implements
  this contract feeds that picker: the inventory adapter in
  production, a Mox double in tests. Following the hexagonal record
  in `holographic-item-memory`, a `*_source` port reads data inbound
  and `state` is the adapter's opaque handle.

  The entry shape matches `src/library/aiModelsCatalog.js`, because
  phase 1 of RFD 0019 must serve what the client already reads.
  """

  @type state :: term()
  @type feature :: String.t()
  @type entry :: %{value: String.t(), label: String.t(), feature: feature()}

  @typedoc """
  A catalog entry with its provenance.

  Catalog facts change often, so each carries a trust score in
  `[0.0, 1.0]` and the time it last moved. The field names follow the
  hermes-agent holographic memory store: `content` is the fact text,
  `category` groups it, `tags` label it.
  """
  @type fact :: %{
          fact_id: String.t(),
          content: String.t(),
          category: String.t(),
          tags: [String.t()],
          trust_score: float(),
          updated_at: DateTime.t()
        }

  @doc "Every catalog entry the picker may offer."
  @callback list_models(state()) :: [entry()]

  @doc "Entries for one API feature key, such as `image_to_textured_mesh`."
  @callback list_for_feature(state(), feature()) :: [entry()]

  @doc "Every distinct feature key present in the catalog."
  @callback list_features(state()) :: [feature()]

  @doc "Every catalog entry as a trust-scored fact."
  @callback list_facts(state()) :: [fact()]

  @doc "Facts at or above a trust floor, highest trust first."
  @callback list_facts_above(state(), min_trust :: float()) :: [fact()]
end
