# SPDX-License-Identifier: MIT

defmodule WeftspunCMS.CompositionOfDomainsTest do
  @moduledoc """
  The one test that mocks nothing.

  RFD 0054 mocks every port and keeps the planning documents real. A
  mocked domain proves nothing about the pipeline, because the domains
  are the pipeline.

  This file therefore runs the real planner over the real documents,
  and it asserts what composition is supposed to buy.
  """

  use ExUnit.Case, async: true

  alias WeftspunCMS.Core.Adapters.TaskweftPlanner
  alias WeftspunCMS.Planning.Loader

  defp plan(pipeline) do
    {:ok, %{base: base, overlays: overlays}} = Loader.load(pipeline)
    TaskweftPlanner.plan(base, overlays)
  end

  defp actions(plan), do: Enum.map(plan, &hd/1)

  describe "the base domain plans alone" do
    test "content_only reaches published with no stage" do
      assert {:ok, plan} = plan(:content_only)

      assert actions(plan) == ["a_mark_staged", "a_validate", "a_publish"]
    end
  end

  describe "a stage document overrides the base" do
    test "the mesh stage replaces run_stages, and the lifecycle stays" do
      assert {:ok, plan} = plan(:mesh)
      names = actions(plan)

      # The stage the overlay added.
      assert "a_generate_mesh" in names
      assert "a_unwrap_uv" in names

      # The lifecycle below never learned that a mesh model exists, and
      # its own steps still run, in order, at the end.
      assert List.last(names) == "a_publish"
      assert Enum.at(names, -2) == "a_validate"
    end

    test "the base default is gone once a stage overrides it" do
      {:ok, base_plan} = plan(:content_only)
      {:ok, mesh_plan} = plan(:mesh)

      # :no_stage went straight to a_mark_staged. The override does the
      # work first, thus the plan grew.
      assert length(mesh_plan) > length(base_plan)
    end
  end

  describe "three documents compose" do
    test "the rig stage overrides the mesh override" do
      assert {:ok, plan} = plan(:avatar)
      names = actions(plan)

      assert "a_generate_mesh" in names
      assert "a_rig" in names
      assert List.last(names) == "a_publish"
    end

    test "the rig calls an action the mesh document defines" do
      # a_generate_mesh lives in stage_mesh, and stage_rig's
      # run_stages calls it. That resolves only because compose merges
      # the actions of every document before the planner sees them.
      assert {:ok, plan} = plan(:avatar)
      names = actions(plan)

      mesh_index = Enum.find_index(names, &(&1 == "a_generate_mesh"))
      rig_index = Enum.find_index(names, &(&1 == "a_rig"))

      assert mesh_index < rig_index
    end

    test "a model unloads before the next one loads" do
      # RFD 0027. The peak is one model, and not the sum.
      assert {:ok, plan} = plan(:avatar)
      names = actions(plan)

      unload_mesh = Enum.find_index(names, &(&1 == "a_unload_mesh_model"))
      load_rig = Enum.find_index(names, &(&1 == "a_load_rig_model"))

      assert unload_mesh < load_rig
    end
  end

  describe "the problem overlay wins" do
    test "the avatar problem sets the transmission format to vrm" do
      {:ok, %{base: base, overlays: overlays}} = Loader.load(:avatar)
      {:ok, composed} = Taskweft.Compose.compose_strings([base | overlays], format: "dsl")
      {:ok, document} = Jason.decode(composed)

      format = Enum.find(document["variables"], &(&1["name"] == "format"))

      # The base initialises transmission to "glb". The problem goes
      # last, thus its value stands.
      assert format["init"]["transmission"] == "vrm"
      assert format["init"]["internal"] == "usd"
    end

    test "the problem goal replaces the base todo_list" do
      {:ok, %{base: base, overlays: overlays}} = Loader.load(:avatar)
      {:ok, composed} = Taskweft.Compose.compose_strings([base | overlays], format: "dsl")
      {:ok, document} = Jason.decode(composed)

      assert [%{"goal" => [%{"pointer" => "/have/published", "eq" => true}]}] =
               document["todo_list"]
    end
  end

  describe "a stage document is a fragment, and not a domain" do
    test "the base validates alone, because it needs nothing else" do
      source = File.read!(Loader.domain_path("content_lifecycle"))
      assert :ok = TaskweftPlanner.validate(source)
    end

    test "a stage document alone is rejected, and the message names the call" do
      # stage_mesh calls a_mark_staged, which only the lifecycle
      # defines. Alone it is incomplete, and the planner says so
      # rather than answering no_plan later.
      source = File.read!(Loader.domain_path("stage_mesh"))

      assert {:error, message} = TaskweftPlanner.validate(source)
      assert message =~ "a_mark_staged"
    end

    test "the same fragment composes, because the base supplies the call" do
      {:ok, %{base: base, overlays: overlays}} = Loader.load(:mesh)
      assert {:ok, _plan} = TaskweftPlanner.plan(base, overlays)
    end
  end
end
