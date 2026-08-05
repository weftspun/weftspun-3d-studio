# SPDX-License-Identifier: MIT

defmodule WeftspunCMS.DomainTest do
  @moduledoc """
  The pure rules. No mocks appear here, because nothing reaches a side.

  RFD 0023 keeps `domain/` free of I/O, and this file is the check on
  that: a test that needed a mock would mean the rule leaked.
  """

  use ExUnit.Case, async: true

  alias WeftspunCMS.Core.Domain.{Job, Model, Pipeline}

  describe "Model.weight_gb/1" do
    test "bf16 holds one parameter in 2 bytes" do
      model = %Model{id: "m", feature: "f", parameters_billions: 4.0, format: :bf16}
      assert {:ok, 8.0} = Model.weight_gb(model)
    end

    test "Q4_K_M holds one parameter in about 0.55 bytes" do
      model = %Model{id: "m", feature: "f", parameters_billions: 27.0, format: :q4_k_m}
      assert {:ok, 14.85} = Model.weight_gb(model)
    end

    test "an absent count is unknown, and never a guess" do
      model = %Model{id: "m", feature: "f", parameters_billions: nil}
      assert :unknown = Model.weight_gb(model)
    end
  end

  describe "Model.resident_gb/1" do
    test "adds the 10 percent runtime overhead from RFD 0025" do
      model = %Model{id: "m", feature: "f", parameters_billions: 4.0}
      assert {:ok, 8.8} = Model.resident_gb(model)
    end
  end

  describe "Model.total_weight_gb/1" do
    test "reports what it could not count" do
      models = [
        %Model{id: "a", feature: "f", parameters_billions: 4.0},
        %Model{id: "b", feature: "f", parameters_billions: nil},
        %Model{id: "c", feature: "f", parameters_billions: 0.5}
      ]

      assert %{total_gb: 9.0, unknown: ["b"]} = Model.total_weight_gb(models)
    end
  end

  describe "Model.fits?/3" do
    test "a set with an unknown member never fits" do
      models = [%Model{id: "a", feature: "f", parameters_billions: nil}]
      refute Model.fits?(models, 128.0)
    end

    test "the headroom counts against the device" do
      models = [%Model{id: "a", feature: "f", parameters_billions: 4.0}]

      assert Model.fits?(models, 10.0)
      refute Model.fits?(models, 10.0, 3.0)
    end
  end

  describe "Job.transition/2" do
    test "a run moves forward" do
      job = %Job{id: "j", state: :queued}
      assert {:ok, %Job{state: :running}} = Job.transition(job, :running)
    end

    test "a failure may retry" do
      job = %Job{id: "j", state: :failed}
      assert {:ok, %Job{state: :running}} = Job.transition(job, :running)
    end

    test "a finished job does not move, and the refusal is an error" do
      job = %Job{id: "j", state: :done}
      assert {:error, message} = Job.transition(job, :running)
      assert message =~ "cannot move from done to running"
    end
  end

  describe "Job.resume_at/1" do
    test "needs both the plan and the failed step" do
      assert :not_resumable = Job.resume_at(%Job{id: "j", state: :failed, plan: nil})
      assert :not_resumable = Job.resume_at(%Job{id: "j", state: :failed, failed_step: nil})
    end

    test "a step past the end of the plan cannot resume" do
      job = %Job{id: "j", state: :failed, plan: [["a"]], failed_step: 5}
      assert :not_resumable = Job.resume_at(job)
    end

    test "gives the step the replan starts from" do
      job = %Job{id: "j", state: :failed, plan: [["a"], ["b"], ["c"]], failed_step: 1}
      assert {:ok, 1} = Job.resume_at(job)
    end
  end

  describe "Job.progress/1" do
    test "a plan of no steps is complete" do
      assert Job.progress(%Job{id: "j", state: :done, plan: []}) == 1.0
    end

    test "no plan is no progress" do
      assert Job.progress(%Job{id: "j", state: :queued}) == 0.0
    end

    test "counts the steps that finished" do
      job = %Job{id: "j", state: :running, plan: [["a"], ["b"], ["c"], ["d"]], completed_steps: 3}
      assert Job.progress(job) == 0.75
    end
  end

  describe "Pipeline.documents/1" do
    test "the base leads every pipeline" do
      assert {:ok, %{domains: ["content_lifecycle" | _rest]}} = Pipeline.documents(:avatar)
    end

    test "the stages follow in order" do
      assert {:ok, %{domains: domains, problem: "avatar"}} = Pipeline.documents(:avatar)
      assert domains == ["content_lifecycle", "stage_mesh", "stage_rig"]
    end

    test "an unknown name is an error, and not a raise" do
      assert {:error, :unknown_pipeline} = Pipeline.documents(:nope)
    end
  end

  describe "Pipeline.shares_stage?/2" do
    test "two pipelines that both make a mesh share that document" do
      assert Pipeline.shares_stage?(:mesh, :avatar)
    end

    test "the base alone is not a shared stage" do
      refute Pipeline.shares_stage?(:content_only, :mesh)
    end
  end
end
