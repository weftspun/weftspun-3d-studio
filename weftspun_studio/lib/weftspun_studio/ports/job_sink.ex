# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule WeftspunStudio.Ports.JobSink do
  @moduledoc """
  Driven sink port: send job commands outward to the DGX backend.

  A `*_sink` port transmits core-side facts to the outside world.
  `state` is the adapter's opaque handle.

  Mox implements this in tests. RFD 0019 gives the real adapter a
  later phase.
  """

  @type state :: term()
  @type job_id :: String.t()

  @doc "Submit work and return the new job id."
  @callback create_job(state(), feature :: String.t(), model :: String.t(), params :: map()) ::
              {:ok, job_id()} | {:error, term()}

  @doc "Ask the backend to stop a job."
  @callback cancel_job(state(), job_id()) :: :ok | {:error, term()}
end
