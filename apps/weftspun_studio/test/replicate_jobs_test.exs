# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule WeftspunStudio.ReplicateJobsTest do
  @moduledoc """
  The translation the adapter does, tested without a network.

  Two vocabularies meet here. Replicate reports six statuses, and
  RFD 0003 names four. A catalog model id is not a Replicate version.
  Both mappings are pure, thus both are testable on their own.
  """

  use ExUnit.Case, async: true

  alias WeftspunStudio.Adapters.ReplicateJobs

  @models %{
    "pixal3d_image_to_textured_mesh" => "weftspun/pixal3d:abc123",
    "trellis2_image_to_textured_mesh" => "weftspun/trellis2:def456"
  }

  setup do
    Application.put_env(:weftspun_studio, :replicate_models, @models)
    on_exit(fn -> Application.delete_env(:weftspun_studio, :replicate_models) end)
    :ok
  end

  describe "resolve/1" do
    test "maps a catalog id to the Replicate version" do
      assert {:ok, "weftspun/pixal3d:abc123"} =
               ReplicateJobs.resolve("pixal3d_image_to_textured_mesh")
    end

    test "an unmapped id is named, and not passed through" do
      # Passing an unknown id through would send Replicate a request
      # that fails there, and the message would name their vocabulary
      # instead of ours.
      assert {:error, {:unknown_model, "nope"}} = ReplicateJobs.resolve("nope")
    end
  end

  describe "a missing token is caught before the request" do
    test "create_job answers without reaching the network" do
      Application.delete_env(:weftspun_studio, :replicate_token)
      existing = System.get_env("REPLICATE_API_TOKEN")
      System.delete_env("REPLICATE_API_TOKEN")

      on_exit(fn ->
        if existing, do: System.put_env("REPLICATE_API_TOKEN", existing)
      end)

      assert {:error, :no_replicate_token} =
               ReplicateJobs.create_job(nil, "f", "pixal3d_image_to_textured_mesh", %{})
    end

    test "an unknown model is caught before the token is read" do
      # resolve/1 runs first in the with chain, thus the caller's
      # fault is reported even when this server is misconfigured.
      assert {:error, {:unknown_model, "nope"}} =
               ReplicateJobs.create_job(nil, "f", "nope", %{})
    end
  end
end
