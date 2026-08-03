# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule WeftspunStudio.Ports.FactSink do
  @moduledoc """
  Driven sink port: write catalog facts and their trust outward.

  Catalog entries are facts, not fixed rows. A licence gate vetoes a
  model. A benchmark moves a recommendation. A backend drops a model.
  RFD 0016 records that churn, so the store carries a trust score and
  a timestamp per fact, after the hermes-agent holographic memory
  store.

  `state` is the adapter's opaque handle.
  """

  @type state :: term()
  @type fact_id :: String.t()

  @doc "Store or replace one catalog fact."
  @callback upsert_fact(state(), fact_id(), attrs :: map()) :: :ok | {:error, term()}

  @doc """
  Move a fact's trust after use.

  Returns the old and the new score, matching the hermes
  `record_feedback` result.
  """
  @callback record_feedback(state(), fact_id(), helpful? :: boolean()) ::
              {:ok, %{fact_id: fact_id(), old_trust: float(), new_trust: float()}}
              | {:error, term()}

  @doc "Drop a fact that no longer holds."
  @callback retract_fact(state(), fact_id()) :: :ok | {:error, term()}
end
