# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule WeftspunStudio.Ports.Planner do
  @moduledoc """
  Driven port: solve a pipeline into ordered steps.

  A content pipeline runs several models in order. The order, the
  guards, and the load and unload pairs live in a RECTGTN domain, and
  not in this code. RFD 0037 records why a script cannot hold them.

  `state` is the adapter's opaque handle, matching the other ports
  here. Mox implements this in tests.
  """

  @type state :: term()

  @typedoc "A RECTGTN document, as Elixir DSL source."
  @type document :: String.t()

  @typedoc "One step. The head names an action, and the tail are its arguments."
  @type step :: [String.t()]

  @typedoc "A solved plan, in order."
  @type plan :: [step()]

  @doc """
  Solves a base document with the overlays composed over it.

  The overlays apply left to right, and a later one wins. A problem is
  an ordinary overlay.
  """
  @callback plan(state(), document(), [document()]) :: {:ok, plan()} | {:error, term()}

  @doc """
  Resumes a plan from the step that failed.

  The work before `fail_step` stands. That is the whole reason a
  pipeline is a domain and not a script.
  """
  @callback replan(state(), document(), plan(), non_neg_integer()) ::
              {:ok, plan()} | {:error, term()}

  @doc """
  Checks a document, and returns no plan.

  A stage document alone is a fragment. It calls actions the base
  defines, thus it fails this check and still composes.
  """
  @callback validate(state(), document()) :: :ok | {:error, term()}
end
