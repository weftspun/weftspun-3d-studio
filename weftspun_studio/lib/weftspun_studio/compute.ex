defmodule WeftspunStudio.Compute do
  @moduledoc """
  Tensor backend for the studio core.

  RFD 0019 first selected EXLA. XLA publishes no Windows archive, and
  nine of its nine release assets are for other systems, thus a
  Windows host could never build it.

  Torchx replaces it. Torchx binds LibTorch, which ships for Windows,
  macOS, and Linux, and it carries a CUDA build for each. One backend
  therefore covers every host this project runs on.

  ## Let it crash

  This module runs no `try`. A missing backend is an expected state,
  and `available?/0` answers it, thus every function returns
  `{:error, :backend_unavailable}` for that one case.

  Anything else is a fault. A LibTorch that loads and then fails a
  multiply is broken, and a rescue here would report that as an
  ordinary error tuple and let the caller carry on with a broken
  backend. The supervisor is the right place for it.
  """

  @backend_name "Torchx"

  @doc "True when the Torchx backend compiled and loaded."
  @spec available?() :: boolean()
  def available?, do: Code.ensure_loaded?(Torchx)

  @doc """
  Devices the local LibTorch build supports.

  Returns a map such as `%{cpu: 1, cuda: 1}`, where the value counts
  the devices.
  """
  @spec platforms() :: {:ok, map()} | {:error, :backend_unavailable}
  def platforms do
    if available?() do
      {:ok, %{cpu: 1, cuda: cuda_device_count()}}
    else
      {:error, :backend_unavailable}
    end
  end

  @doc "True when LibTorch reports at least one CUDA device."
  @spec cuda?() :: boolean()
  def cuda? do
    case platforms() do
      {:ok, map} -> Map.get(map, :cuda, 0) > 0
      {:error, :backend_unavailable} -> false
    end
  end

  @doc """
  Describes the compute backend.

  Returns `{:ok, info}` when Torchx is present, or
  `{:error, :backend_unavailable}` when it did not build.
  """
  @spec info() :: {:ok, map()} | {:error, :backend_unavailable}
  def info do
    if available?() do
      {:ok,
       %{
         backend: @backend_name,
         accelerator: if(cuda?(), do: "cuda", else: "cpu"),
         platforms: describe_platforms(),
         nx_version: application_version(:nx),
         torchx_version: application_version(:torchx),
         libtorch_target: System.get_env("LIBTORCH_TARGET", "unset (cpu only)")
       }}
    else
      {:error, :backend_unavailable}
    end
  end

  @doc """
  Runs a small tensor op through the backend.

  This proves LibTorch loaded and executed. It is a health check for
  the accelerator before a real model runs.

  A backend that loads and then fails this crashes the caller. That is
  the intent. A tensor multiply that does not work is not a condition
  to handle.
  """
  @spec smoke_test() :: {:ok, number()} | {:error, :backend_unavailable}
  def smoke_test do
    if available?() do
      a = Nx.tensor([1.0, 2.0, 3.0], type: :f32)
      b = Nx.tensor([4.0, 5.0, 6.0], type: :f32)

      {:ok, a |> Nx.multiply(b) |> Nx.sum() |> Nx.to_number()}
    else
      {:error, :backend_unavailable}
    end
  end

  # An older Torchx exports no device_count/1. That is a version
  # question and not a fault, thus it answers 0 rather than crashing.
  defp cuda_device_count do
    if function_exported?(Torchx, :device_count, 1) do
      Torchx.device_count(:cuda)
    else
      0
    end
  end

  defp describe_platforms do
    case platforms() do
      {:ok, map} -> Enum.map_join(map, ", ", fn {name, count} -> "#{name}=#{count}" end)
      {:error, reason} -> "unavailable (#{inspect(reason)})"
    end
  end

  defp application_version(app) do
    case Application.spec(app, :vsn) do
      nil -> "unknown"
      vsn -> List.to_string(vsn)
    end
  end
end
