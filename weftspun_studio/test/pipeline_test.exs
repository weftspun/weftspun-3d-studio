# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule WeftspunStudio.PipelineTest do
  @moduledoc """
  The planning documents are the one part of the pipeline that no test
  mocks. A mocked domain proves nothing about the order, because the
  documents are the order.

  These tests run the real planner over the real documents in
  `priv/domains` and `priv/problems`.
  """

  use ExUnit.Case, async: true

  alias WeftspunStudio.Adapters.TaskweftPlanner
  alias WeftspunStudio.Pipeline

  defp plan(pipeline) do
    {:ok, %{base: base, overlays: overlays}} = Pipeline.load(pipeline)
    TaskweftPlanner.plan(nil, base, overlays)
  end

  defp actions(steps), do: Enum.map(steps, &hd/1)

  describe "documents/1" do
    test "the base leads every pipeline" do
      assert {:ok, %{domains: ["content_lifecycle" | _rest]}} = Pipeline.documents(:avatar)
    end

    test "the stages follow in compose order" do
      assert {:ok, %{domains: domains, problem: "avatar"}} = Pipeline.documents(:avatar)
      assert domains == ["content_lifecycle", "stage_mesh", "stage_rig"]
    end

    test "an unknown name is an error, and not a raise" do
      assert {:error, :unknown_pipeline} = Pipeline.documents(:nope)
    end
  end

  describe "parse/1" do
    test "reads a known name" do
      assert {:ok, :avatar} = Pipeline.parse("avatar")
    end

    test "an unknown name never creates an atom" do
      # String.to_existing_atom/1 keeps an HTTP caller from filling the
      # atom table, which never shrinks.
      assert {:error, :unknown_pipeline} = Pipeline.parse("definitely_not_a_pipeline_name")
    end
  end

  describe "the base domain plans alone" do
    test "content_only reaches published with no stage" do
      assert {:ok, steps} = plan(:content_only)
      assert actions(steps) == ["a_mark_staged", "a_validate", "a_publish"]
    end
  end

  describe "a stage document overrides the base" do
    test "the mesh stage replaces run_stages, and the lifecycle stays" do
      assert {:ok, steps} = plan(:mesh)
      names = actions(steps)

      assert "a_generate_mesh" in names
      assert "a_unwrap_uv" in names

      # The lifecycle never learned that a mesh model exists, and its
      # own steps still close the plan.
      assert List.last(names) == "a_publish"
      assert Enum.at(names, -2) == "a_validate"
    end

    test "the base default is gone once a stage overrides it" do
      {:ok, base_steps} = plan(:content_only)
      {:ok, mesh_steps} = plan(:mesh)

      assert length(mesh_steps) > length(base_steps)
    end
  end

  describe "three documents compose" do
    test "the rig calls an action the mesh document defines" do
      # a_generate_mesh lives in stage_mesh, and stage_rig's run_stages
      # calls it. That resolves only because the merge unions the
      # actions of every document before the planner sees them.
      assert {:ok, steps} = plan(:avatar)
      names = actions(steps)

      assert Enum.find_index(names, &(&1 == "a_generate_mesh")) <
               Enum.find_index(names, &(&1 == "a_rig"))
    end

    test "a model unloads before the next one loads" do
      # RFD 0027. The peak is one model, and not the sum.
      assert {:ok, steps} = plan(:avatar)
      names = actions(steps)

      assert Enum.find_index(names, &(&1 == "a_unload_mesh_model")) <
               Enum.find_index(names, &(&1 == "a_load_rig_model"))
    end
  end

  describe "the problem overlay wins" do
    test "the avatar problem sets the transmission format to vrm" do
      {:ok, %{base: base, overlays: overlays}} = Pipeline.load(:avatar)
      {:ok, composed} = Taskweft.Compose.compose_strings([base | overlays], format: "dsl")
      {:ok, document} = Jason.decode(composed)

      format = Enum.find(document["variables"], &(&1["name"] == "format"))

      # The base initialises transmission to "glb". The problem goes
      # last, thus its value stands.
      assert format["init"]["transmission"] == "vrm"
      assert format["init"]["internal"] == "usd"
    end
  end

  describe "a stage document is a fragment" do
    test "the base validates alone, because it needs nothing else" do
      source = File.read!(Pipeline.domain_path("content_lifecycle"))
      assert :ok = TaskweftPlanner.validate(nil, source)
    end

    test "a stage alone is rejected, and the message names the call" do
      source = File.read!(Pipeline.domain_path("stage_mesh"))

      assert {:error, message} = TaskweftPlanner.validate(nil, source)
      assert message =~ "a_mark_staged"
    end
  end
end
