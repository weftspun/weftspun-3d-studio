defmodule WeftspunStudio.Model do
  @moduledoc """
  One model entry from the inventory in RFD 0016.

  A model has an id, a type, a task, and a runtime location. The type
  separates a neural model from a geometric algorithm, which is the
  distinction RFD 0016 exists to record.
  """

  @type model_type :: :deep_learning | :geometric
  @type runs_on :: :dgx_api | :local | :external
  @type group :: :core | :environment | :splat | :legacy | :component
  @type status :: :active | :legacy | :vetoed

  @type t :: %__MODULE__{
          id: String.t(),
          type: model_type(),
          task: String.t(),
          runs_on: runs_on(),
          group: group(),
          status: status(),
          note: String.t() | nil
        }

  @enforce_keys [:id, :type, :task, :runs_on, :group, :status]
  defstruct [:id, :type, :task, :runs_on, :group, :status, :note]

  @doc "True when the model is available for new work."
  @spec active?(t()) :: boolean()
  def active?(%__MODULE__{status: :active}), do: true
  def active?(%__MODULE__{}), do: false

  @doc "True when a licence gate or a review removed the model."
  @spec vetoed?(t()) :: boolean()
  def vetoed?(%__MODULE__{status: :vetoed}), do: true
  def vetoed?(%__MODULE__{}), do: false
end
