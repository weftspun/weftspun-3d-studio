# SPDX-License-Identifier: MIT

defmodule WeftspunCMS.Core.Domain.Job do
  @moduledoc """
  A pipeline run, and the rules about its state.

  Pure. RFD 0003 records the lifecycle, and this module holds the part
  that is a rule rather than a store.

  A job carries the plan it runs and the step it reached. `resume_at/1`
  turns that pair into the argument `Planner.replan/3` takes.
  """

  @enforce_keys [:id, :state]
  defstruct [:id, :state, :pipeline, :plan, :failed_step, :asset_id, completed_steps: 0]

  @type state :: :queued | :running | :failed | :done
  @type t :: %__MODULE__{
          id: String.t(),
          state: state(),
          pipeline: atom() | nil,
          plan: [[String.t()]] | nil,
          failed_step: non_neg_integer() | nil,
          asset_id: String.t() | nil,
          completed_steps: non_neg_integer()
        }

  # A run only moves forward, except that a failure may retry.
  @transitions %{
    queued: [:running],
    running: [:done, :failed],
    failed: [:running],
    done: []
  }

  @doc "The states this job may move to."
  @spec next_states(t()) :: [state()]
  def next_states(%__MODULE__{state: state}), do: Map.get(@transitions, state, [])

  @doc """
  Moves the job, or says why it cannot move.

  A rejected move is an error and not a raise. A caller that gets a
  stale state from a store must handle it, and a raise would make that
  a crash.
  """
  @spec transition(t(), state()) :: {:ok, t()} | {:error, String.t()}
  def transition(%__MODULE__{} = job, target) do
    if target in next_states(job) do
      {:ok, %{job | state: target}}
    else
      {:error, "a job cannot move from #{job.state} to #{target}"}
    end
  end

  @doc """
  The step a resume starts from.

  Returns `:not_resumable` when the job holds no plan, or when nothing
  failed. A resume needs both, because the plan gives the steps and the
  failed step gives the place.
  """
  @spec resume_at(t()) :: {:ok, non_neg_integer()} | :not_resumable
  def resume_at(%__MODULE__{plan: nil}), do: :not_resumable
  def resume_at(%__MODULE__{failed_step: nil}), do: :not_resumable

  def resume_at(%__MODULE__{plan: plan, failed_step: step})
      when is_integer(step) and step >= 0 do
    if step < length(plan), do: {:ok, step}, else: :not_resumable
  end

  def resume_at(%__MODULE__{}), do: :not_resumable

  @doc """
  How far the run got, as a fraction.

  Returns 0.0 for a job with no plan. A plan of no steps is complete,
  because nothing is left to run.
  """
  @spec progress(t()) :: float()
  def progress(%__MODULE__{plan: nil}), do: 0.0
  def progress(%__MODULE__{plan: []}), do: 1.0

  def progress(%__MODULE__{plan: plan, completed_steps: done}) do
    Float.round(min(done, length(plan)) / length(plan), 4)
  end
end
