# SPDX-License-Identifier: MIT

defmodule WeftspunCMS.Core.Domain.Model do
  @moduledoc """
  A catalog model, and the rules about its memory.

  Pure. It reaches no store, no network, and no planner. RFD 0023 keeps
  `domain/` that way.

  RFD 0025 gives the arithmetic this module holds, and RFD 0027 gives
  the budget it serves.
  """

  @enforce_keys [:id, :feature]
  defstruct [
    :id,
    :feature,
    :label,
    :license,
    :parameters_billions,
    format: :bf16,
    composite: false
  ]

  @type format :: :bf16 | :q4_k_m
  @type t :: %__MODULE__{
          id: String.t(),
          feature: String.t(),
          label: String.t() | nil,
          license: String.t() | nil,
          parameters_billions: float() | nil,
          format: format(),
          composite: boolean()
        }

  # RFD 0025. bf16 holds one parameter in 2 bytes, and Q4_K_M holds one
  # in about 0.55 bytes.
  @bytes_per_parameter %{bf16: 2.0, q4_k_m: 0.55}

  # RFD 0025. A CUDA context, the allocator, and the fragmentation add
  # about 10 percent above the weights.
  @runtime_overhead 1.1

  @doc """
  The weight size in GB, for the model's declared format.

  Returns `:unknown` when the parameter count is absent. RFD 0026 marks
  two models that way, and a guessed number would move the RFD 0027
  budget.
  """
  @spec weight_gb(t()) :: {:ok, float()} | :unknown
  def weight_gb(%__MODULE__{parameters_billions: nil}), do: :unknown

  def weight_gb(%__MODULE__{parameters_billions: count, format: format}) do
    {:ok, Float.round(count * @bytes_per_parameter[format], 2)}
  end

  @doc """
  The device memory one resident model needs, without its activations.

  The activation peak depends on the resolution and the batch size, and
  not on the parameter count, thus a caller adds it.
  """
  @spec resident_gb(t()) :: {:ok, float()} | :unknown
  def resident_gb(%__MODULE__{} = model) do
    case weight_gb(model) do
      {:ok, gb} -> {:ok, Float.round(gb * @runtime_overhead, 2)}
      :unknown -> :unknown
    end
  end

  @doc """
  Sums the weights of a set, and reports what it could not count.

  The unknown list is the point. RFD 0027 records that the catalog
  total excludes the most used model, and a sum that hid that would
  read as a closed budget.
  """
  @spec total_weight_gb([t()]) :: %{total_gb: float(), unknown: [String.t()]}
  def total_weight_gb(models) when is_list(models) do
    {total, unknown} =
      Enum.reduce(models, {0.0, []}, fn model, {sum, missing} ->
        case weight_gb(model) do
          {:ok, gb} -> {sum + gb, missing}
          :unknown -> {sum, [model.id | missing]}
        end
      end)

    %{total_gb: Float.round(total, 2), unknown: Enum.reverse(unknown)}
  end

  @doc """
  True when the set fits the device, with the activation headroom named.

  A set with an unknown member never fits, because a total that omits a
  model is not a total.
  """
  @spec fits?([t()], number(), number()) :: boolean()
  def fits?(models, device_gb, headroom_gb \\ 0.0) do
    case total_weight_gb(models) do
      %{unknown: [_ | _]} -> false
      %{total_gb: total} -> total + headroom_gb <= device_gb
    end
  end
end
