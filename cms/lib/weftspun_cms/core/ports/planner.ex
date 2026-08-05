# SPDX-License-Identifier: MIT

defmodule WeftspunCMS.Core.Ports.Planner do
  @moduledoc """
  The port for the HTN planner.

  A content pipeline runs several stages in order. The order, the
  guards, and the memory budget live in a planning domain, and not in
  this code. RFD 0037 records why.

  The port hides taskweft. The core calls this behaviour, thus a test
  needs no planner and no C++ NIF.
  """

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
  @callback plan(document(), [document()]) :: {:ok, plan()} | {:error, String.t()}

  @doc """
  Resumes a plan from the step that failed.

  The work before `fail_step` stands. That is the whole reason a
  pipeline is a domain and not a script.
  """
  @callback replan(document(), plan(), non_neg_integer()) ::
              {:ok, plan()} | {:error, String.t()}

  @doc """
  Checks a document, and returns no plan.

  A domain that does not validate cannot plan, and the validation
  message names the fault.
  """
  @callback validate(document()) :: :ok | {:error, String.t()}
end
