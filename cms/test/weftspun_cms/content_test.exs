# SPDX-License-Identifier: MIT

defmodule WeftspunCMS.ContentTest do
  @moduledoc """
  Every port is a Mox mock here. The planning documents are real, and
  they are the only real thing. RFD 0054 records that split.

  A mocked planner proves the composition order reaches it. Whether
  that order plans is a question for the planner, and RFD 0037 already
  answered it with a solved plan.
  """

  use ExUnit.Case, async: true

  import Mox

  alias WeftspunCMS.Content
  alias WeftspunCMS.Core.Domain.Job

  setup :verify_on_exit!

  defp content(overrides \\ []) do
    WeftspunCMS.Composition.build(
      Keyword.merge(
        [
          planner: WeftspunCMS.MockPlanner,
          catalog: WeftspunCMS.MockCatalogSource,
          owned_assets: WeftspunCMS.MockOwnedAssetSource,
          jobs: WeftspunCMS.MockJobStore,
          assets: WeftspunCMS.MockAssetStore
        ],
        overrides
      )
    )
  end

  describe "plan/2 composes the documents" do
    test "the base leads and the overlays follow" do
      expect(WeftspunCMS.MockPlanner, :plan, fn base, overlays ->
        # The base is the lifecycle, and it is first.
        assert base =~ "defmodule WeftspunCMS.Domains.ContentLifecycle"

        # The stages follow, in pipeline order.
        assert [mesh, rig, problem] = overlays
        assert mesh =~ "defmodule WeftspunCMS.Domains.StageMesh"
        assert rig =~ "defmodule WeftspunCMS.Domains.StageRig"

        # The problem goes last, because a later document wins.
        assert problem =~ "defmodule WeftspunCMS.Problems.Avatar"

        {:ok, [["a_generate_mesh"], ["a_rig"]]}
      end)

      assert {:ok, [["a_generate_mesh"], ["a_rig"]]} = Content.plan(content(), :avatar)
    end

    test "a pipeline with no stage sends no overlay" do
      expect(WeftspunCMS.MockPlanner, :plan, fn base, overlays ->
        assert base =~ "ContentLifecycle"
        assert overlays == []
        {:ok, [["a_mark_staged"]]}
      end)

      assert {:ok, _plan} = Content.plan(content(), :content_only)
    end

    test "an unknown pipeline is an error, and reaches no planner" do
      # No expect/3 call. The planner must not be touched, and
      # verify_on_exit! would not catch that on its own, thus the
      # absence of a stub is the assertion.
      assert {:error, :unknown_pipeline} = Content.plan(content(), :no_such_pipeline)
    end
  end

  describe "start/3 stores the plan with the job" do
    test "the job carries the steps a resume needs" do
      steps = [["a_generate_mesh"], ["a_rig"]]

      expect(WeftspunCMS.MockPlanner, :plan, fn _base, _overlays -> {:ok, steps} end)

      expect(WeftspunCMS.MockJobStore, :create, fn attrs ->
        assert attrs.plan == steps
        assert attrs.state == :queued
        assert attrs.pipeline == :avatar
        {:ok, %Job{id: "job_1", state: :queued, plan: steps}}
      end)

      assert {:ok, %Job{id: "job_1"}} = Content.start(content(), :avatar)
    end

    test "a planner failure creates no job" do
      expect(WeftspunCMS.MockPlanner, :plan, fn _base, _overlays -> {:error, "no_plan"} end)

      assert {:error, "no_plan"} = Content.start(content(), :avatar)
    end
  end

  describe "resume/2" do
    test "resumes from the failed step, and keeps the work before it" do
      plan = [["a_generate_mesh"], ["a_unwrap_uv"], ["a_rig"]]

      expect(WeftspunCMS.MockJobStore, :fetch, fn "job_1" ->
        {:ok,
         %Job{
           id: "job_1",
           state: :failed,
           plan: plan,
           failed_step: 2,
           completed_steps: 2
         }}
      end)

      expect(WeftspunCMS.MockPlanner, :replan, fn _base, given_plan, fail_step ->
        assert given_plan == plan
        assert fail_step == 2
        {:ok, [["a_rig"]]}
      end)

      assert {:ok, [["a_rig"]]} = Content.resume(content(), "job_1")
    end

    test "a job with no failed step cannot resume" do
      expect(WeftspunCMS.MockJobStore, :fetch, fn _id ->
        {:ok, %Job{id: "job_1", state: :running, plan: [["a_rig"]], failed_step: nil}}
      end)

      assert {:error, :not_resumable} = Content.resume(content(), "job_1")
    end
  end

  describe "available_traits/2 is headless by default" do
    test "a disabled source answers with the empty set, and reads nothing" do
      expect(WeftspunCMS.MockOwnedAssetSource, :enabled?, fn -> false end)

      # list_owned_trait_ids must not be called. RFD 0023 records that
      # a content deployment serves with no wallet.
      assert {:ok, []} = Content.available_traits(content(), "0xabc")
    end

    test "an enabled source is read" do
      expect(WeftspunCMS.MockOwnedAssetSource, :enabled?, fn -> true end)

      expect(WeftspunCMS.MockOwnedAssetSource, :list_owned_trait_ids, fn "0xabc" ->
        {:ok, ["trait_1"]}
      end)

      assert {:ok, ["trait_1"]} = Content.available_traits(content(), "0xabc")
    end
  end

  describe "models_for/3 respects the budget" do
    test "a model with no measured count never fits" do
      alias WeftspunCMS.Core.Domain.Model

      models = [
        %Model{id: "known", feature: "f", parameters_billions: 4.0},
        %Model{id: "unknown", feature: "f", parameters_billions: nil}
      ]

      expect(WeftspunCMS.MockCatalogSource, :list_models_for_feature, fn "f" -> {:ok, models} end)

      assert {:ok, [%Model{id: "known"}]} = Content.models_for(content(), "f", 16.0)
    end

    test "with no budget every model comes back" do
      alias WeftspunCMS.Core.Domain.Model

      models = [%Model{id: "unknown", feature: "f", parameters_billions: nil}]
      expect(WeftspunCMS.MockCatalogSource, :list_models_for_feature, fn "f" -> {:ok, models} end)

      assert {:ok, [%Model{id: "unknown"}]} = Content.models_for(content(), "f")
    end
  end
end
