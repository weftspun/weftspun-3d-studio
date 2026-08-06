defmodule WeftspunStudio.JobsMoxTest do
  @moduledoc """
  The job ports reach the DGX backend and run model work. RFD 0019
  gives the real adapter a later phase, so these tests pin the
  contract with Mox and run no model work at all.
  """

  use ExUnit.Case, async: true
  import Mox

  alias WeftspunStudio.{JobSinkMock, JobSourceMock}

  setup :verify_on_exit!

  test "create_job returns a job id" do
    expect(JobSinkMock, :create_job, fn _state, feature, model, params ->
      assert feature == "image_to_textured_mesh"
      assert model == "trellis2_image_to_textured_mesh"
      assert params.image_file_id == "file-1"
      {:ok, "job-42"}
    end)

    assert {:ok, "job-42"} =
             JobSinkMock.create_job(
               nil,
               "image_to_textured_mesh",
               "trellis2_image_to_textured_mesh",
               %{image_file_id: "file-1"}
             )
  end

  test "a job moves through the RFD 0003 lifecycle" do
    for status <- [:queued, :running, :completed] do
      expect(JobSourceMock, :fetch_job, fn _state, "job-42" ->
        {:ok, job("job-42", status)}
      end)
    end

    for status <- [:queued, :running, :completed] do
      assert {:ok, %{status: ^status}} = JobSourceMock.fetch_job(nil, "job-42")
    end
  end

  test "a failed job carries an error and no result" do
    expect(JobSourceMock, :fetch_job, fn _state, _id ->
      {:ok, %{job("job-9", :failed) | error: "out of memory", result: nil}}
    end)

    assert {:ok, %{status: :failed, error: "out of memory", result: nil}} =
             JobSourceMock.fetch_job(nil, "job-9")
  end

  test "an unknown job id is not found" do
    expect(JobSourceMock, :fetch_job, fn _state, _id -> {:error, :not_found} end)
    assert {:error, :not_found} = JobSourceMock.fetch_job(nil, "nope")
  end

  test "cancel_job reports success" do
    expect(JobSinkMock, :cancel_job, fn _state, "job-42" -> :ok end)
    assert :ok = JobSinkMock.cancel_job(nil, "job-42")
  end

  test "list_jobs returns newest first" do
    expect(JobSourceMock, :list_jobs, fn _state, 2 ->
      {:ok, [job("job-2", :running), job("job-1", :completed)]}
    end)

    assert {:ok, [%{id: "job-2"}, %{id: "job-1"}]} = JobSourceMock.list_jobs(nil, 2)
  end

  defp job(id, status) do
    %{
      id: id,
      status: status,
      feature: "image_to_textured_mesh",
      model: "trellis2_image_to_textured_mesh",
      progress: if(status == :completed, do: 1.0, else: 0.5),
      result: if(status == :completed, do: %{mesh_url: "/jobs/#{id}/download"}, else: nil),
      error: nil
    }
  end
end
