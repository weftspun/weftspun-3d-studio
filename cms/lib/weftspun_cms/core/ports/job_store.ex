# SPDX-License-Identifier: MIT

defmodule WeftspunCMS.Core.Ports.JobStore do
  @moduledoc """
  The port for the job lifecycle.

  RFD 0023 listed this port as open. RFD 0003 records the lifecycle the
  client already runs.

  A job holds the plan it runs and the step it reached. That pair is
  what makes a resume possible: `Planner.replan/3` takes both.
  """

  alias WeftspunCMS.Core.Domain.Job

  @type id :: String.t()

  @doc "Records a new job, and returns it with its id."
  @callback create(map()) :: {:ok, Job.t()} | {:error, String.t()}

  @doc "One job by id."
  @callback fetch(id()) :: {:ok, Job.t()} | {:error, :not_found}

  @doc "Moves a job to a new state, and records the step it reached."
  @callback update(id(), map()) :: {:ok, Job.t()} | {:error, String.t()}

  @doc "The jobs in one state, newest first."
  @callback list_by_state(Job.state()) :: {:ok, [Job.t()]} | {:error, String.t()}
end
