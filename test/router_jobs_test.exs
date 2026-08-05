# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule WeftspunStudio.RouterJobsTest do
  @moduledoc """
  The job routes pass through to Replicate. These tests mock the ports
  and reach no network, thus they run no model work and cost nothing.

  The error mapping carries most of the weight here. A client that
  gets one 500 for every fault retries a request that can never work.
  """

  use ExUnit.Case, async: true

  import Mox
  import Plug.Test
  import Plug.Conn

  alias WeftspunStudio.{JobSinkMock, JobSourceMock, Router}

  setup :verify_on_exit!

  setup do
    Application.put_env(:weftspun_studio, :job_sink, JobSinkMock)
    Application.put_env(:weftspun_studio, :job_source, JobSourceMock)

    on_exit(fn ->
      Application.delete_env(:weftspun_studio, :job_sink)
      Application.delete_env(:weftspun_studio, :job_source)
    end)

    :ok
  end

  defp call(conn), do: Router.call(conn, Router.init([]))

  defp post_json(path, body) do
    :post
    |> conn(path, Jason.encode!(body))
    |> put_req_header("content-type", "application/json")
    |> call()
  end

  defp body(conn), do: Jason.decode!(conn.resp_body)

  describe "POST /api/v1/jobs" do
    test "accepts the job, and answers 202 with the id" do
      expect(JobSinkMock, :create_job, fn _state, feature, model, params ->
        assert feature == "image_to_textured_mesh"
        assert model == "pixal3d_image_to_textured_mesh"
        assert params == %{"image" => "https://example.invalid/a.png"}
        {:ok, "pred-1"}
      end)

      conn =
        post_json("/api/v1/jobs", %{
          feature: "image_to_textured_mesh",
          model: "pixal3d_image_to_textured_mesh",
          params: %{image: "https://example.invalid/a.png"}
        })

      assert conn.status == 202
      assert body(conn) == %{"job_id" => "pred-1", "status" => "queued"}
    end

    test "a job with no params sends an empty map, and does not fail" do
      expect(JobSinkMock, :create_job, fn _state, _feature, _model, params ->
        assert params == %{}
        {:ok, "pred-2"}
      end)

      conn = post_json("/api/v1/jobs", %{feature: "f", model: "m"})
      assert conn.status == 202
    end

    test "an unknown model is 400, and not 500" do
      # The caller can fix this. A 500 would send them to retry a
      # request that can never work.
      expect(JobSinkMock, :create_job, fn _s, _f, _m, _p ->
        {:error, {:unknown_model, "no_such_model"}}
      end)

      conn = post_json("/api/v1/jobs", %{feature: "f", model: "no_such_model"})

      assert conn.status == 400
      assert body(conn)["model"] == "no_such_model"
    end

    test "a missing token is 503, because the fault is this server's" do
      expect(JobSinkMock, :create_job, fn _s, _f, _m, _p -> {:error, :no_replicate_token} end)

      conn = post_json("/api/v1/jobs", %{feature: "f", model: "m"})
      assert conn.status == 503
    end

    test "a rejection from Replicate is 502, and it carries the detail" do
      expect(JobSinkMock, :create_job, fn _s, _f, _m, _p ->
        {:error, {:replicate_error, 422, "input.image is required"}}
      end)

      conn = post_json("/api/v1/jobs", %{feature: "f", model: "m"})

      assert conn.status == 502
      assert body(conn)["detail"] == "input.image is required"
      assert body(conn)["status"] == 422
    end
  end

  describe "GET /api/v1/jobs/:id" do
    test "returns the job" do
      expect(JobSourceMock, :fetch_job, fn _state, "pred-1" ->
        {:ok,
         %{
           id: "pred-1",
           status: :running,
           feature: "image_to_textured_mesh",
           model: "pixal3d_image_to_textured_mesh",
           progress: 0.0,
           result: nil,
           error: nil
         }}
      end)

      conn = call(conn(:get, "/api/v1/jobs/pred-1"))

      assert conn.status == 200
      assert body(conn)["status"] == "running"
      assert body(conn)["id"] == "pred-1"
    end

    test "an absent job is 404" do
      expect(JobSourceMock, :fetch_job, fn _state, _id -> {:error, :not_found} end)

      conn = call(conn(:get, "/api/v1/jobs/gone"))
      assert conn.status == 404
    end
  end

  describe "GET /api/v1/jobs" do
    test "lists jobs, and passes the limit through" do
      expect(JobSourceMock, :list_jobs, fn _state, limit ->
        assert limit == 3
        {:ok, []}
      end)

      conn = call(conn(:get, "/api/v1/jobs?limit=3"))

      assert conn.status == 200
      assert body(conn) == %{"jobs" => []}
    end

    test "no limit passes nil, and does not invent a default" do
      expect(JobSourceMock, :list_jobs, fn _state, limit ->
        assert limit == nil
        {:ok, []}
      end)

      assert call(conn(:get, "/api/v1/jobs")).status == 200
    end
  end

  describe "POST /api/v1/jobs/:id/cancel" do
    test "cancels the job" do
      expect(JobSinkMock, :cancel_job, fn _state, "pred-1" -> :ok end)

      conn = post_json("/api/v1/jobs/pred-1/cancel", %{})

      assert conn.status == 200
      assert body(conn)["status"] == "canceled"
    end
  end
end
