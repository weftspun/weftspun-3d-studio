# SPDX-License-Identifier: MIT

defmodule WeftspunCMS.Content do
  @moduledoc """
  The API of the headless content system.

  A headless content system holds content and answers for it. It does
  not render, and it holds no wallet. RFD 0023 records that shape.

  Every side arrives as a port. Nothing here picks an adapter, and
  `WeftspunCMS.Composition` is the only module that does.
  """

  alias WeftspunCMS.Core.Domain.{Job, Model, Pipeline}
  alias WeftspunCMS.Planning.Loader

  @enforce_keys [:planner, :catalog, :owned_assets, :jobs, :assets]
  defstruct [:planner, :catalog, :owned_assets, :jobs, :assets]

  @type t :: %__MODULE__{
          planner: module(),
          catalog: module(),
          owned_assets: module(),
          jobs: module(),
          assets: module()
        }

  @doc """
  Solves a pipeline, and returns the ordered steps.

  The documents compose here. The base leads, each stage follows, and
  the problem goes last.
  """
  @spec plan(t(), Pipeline.name()) :: {:ok, [[String.t()]]} | {:error, term()}
  def plan(%__MODULE__{planner: planner}, pipeline) do
    with {:ok, %{base: base, overlays: overlays}} <- Loader.load(pipeline) do
      planner.plan(base, overlays)
    end
  end

  @doc """
  Starts a pipeline, and records the job that runs it.

  The plan is stored with the job. A resume needs the plan and the
  step, and a job that kept only the step could not resume.
  """
  @spec start(t(), Pipeline.name(), map()) :: {:ok, Job.t()} | {:error, term()}
  def start(%__MODULE__{jobs: jobs} = content, pipeline, attrs \\ %{}) do
    with {:ok, steps} <- plan(content, pipeline) do
      jobs.create(Map.merge(attrs, %{pipeline: pipeline, plan: steps, state: :queued}))
    end
  end

  @doc """
  Resumes a failed job from the step that failed.

  The work before the failure stands. A pipeline that lost its last
  stage does not repeat the stages before it.
  """
  @spec resume(t(), String.t()) :: {:ok, [[String.t()]]} | {:error, term()}
  def resume(%__MODULE__{planner: planner, jobs: jobs}, job_id) do
    with {:ok, job} <- jobs.fetch(job_id),
         {:ok, step} <- resume_step(job),
         {:ok, %{base: base}} <- Loader.load(job.pipeline || :content_only) do
      planner.replan(base, job.plan, step)
    end
  end

  defp resume_step(job) do
    case Job.resume_at(job) do
      {:ok, step} -> {:ok, step}
      :not_resumable -> {:error, :not_resumable}
    end
  end

  @doc """
  The models that serve a feature, filtered to what fits the device.

  RFD 0027 records why the filter exists. A model with no measured
  parameter count never fits, thus it never reaches a caller who asked
  for a budget.
  """
  @spec models_for(t(), String.t(), number() | nil) :: {:ok, [Model.t()]} | {:error, term()}
  def models_for(content, feature, device_gb \\ nil)

  def models_for(%__MODULE__{catalog: catalog}, feature, nil) do
    catalog.list_models_for_feature(feature)
  end

  def models_for(%__MODULE__{catalog: catalog}, feature, device_gb) do
    with {:ok, models} <- catalog.list_models_for_feature(feature) do
      {:ok, Enum.filter(models, &Model.fits?([&1], device_gb))}
    end
  end

  @doc """
  The traits a picker may offer this owner.

  With no chain configured the answer is the empty set, and the picker
  shows the locked set. RFD 0023 records that the page still loads.
  """
  @spec available_traits(t(), String.t()) :: {:ok, [String.t()]} | {:error, term()}
  def available_traits(%__MODULE__{owned_assets: source}, address) do
    if source.enabled?() do
      source.list_owned_trait_ids(address)
    else
      {:ok, []}
    end
  end
end
