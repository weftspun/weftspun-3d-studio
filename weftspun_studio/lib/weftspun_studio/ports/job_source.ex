# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule WeftspunStudio.Ports.JobSource do
  @moduledoc """
  Driven source port: read job state inbound from the DGX backend.

  RFD 0003 owns the lifecycle. The client creates a job, polls its
  status, and reads the result. Every call here reaches the backend
  and runs model work.

  This application holds the contract only. Mox implements it in
  tests. A later phase of RFD 0019 adds the real adapter, so no
  heavy model work lands in phase 1.
  """

  @type state :: term()
  @type job_id :: String.t()
  @type status :: :queued | :running | :completed | :failed

  @type job :: %{
          id: job_id(),
          status: status(),
          feature: String.t(),
          model: String.t(),
          progress: float(),
          result: map() | nil,
          error: String.t() | nil
        }

  @doc "Read one job."
  @callback fetch_job(state(), job_id()) :: {:ok, job()} | {:error, :not_found | term()}

  @doc "List recent jobs, newest first."
  @callback list_jobs(state(), limit :: pos_integer() | nil) :: {:ok, [job()]} | {:error, term()}
end
