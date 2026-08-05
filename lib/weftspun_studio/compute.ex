defmodule WeftspunStudio.Compute do
  @moduledoc """
  Tensor backend for the studio core.

  RFD 0019 selects EXLA, and nothing else. EXLA compiles `Nx.Defn`
  graphs with XLA and runs them on an NVIDIA device. Build the
  dependency with `XLA_TARGET=cuda12` so the precompiled binary carries
  the CUDA client.

  XLA publishes no Windows archive, and nine of its nine release assets
  are for other systems. Develop in the dev container, which runs
  Linux. RFD 0056 records it, and this box's own Quadlets run Linux
  too, thus the container matches production.

  A machine with no CUDA device still runs. EXLA falls back to the host
  client.

  ## Let it crash

  This module runs no `try`. A missing backend is an expected state,
  and `available?/0` answers it, thus every function returns
  `{:error, :backend_unavailable}` for that one case.

  Anything else is a fault. An EXLA that loads and then fails a
  multiply is broken, and a rescue here would report that as an
  ordinary error tuple and let the caller carry on with it.
  """

  @doc "True when the EXLA backend compiled and loaded."
  @spec available?() :: boolean()
  def available?, do: Code.ensure_loaded?(EXLA)

  @doc """
  Platforms the local XLA build supports.

  Returns a map such as `%{host: 1, cuda: 1}`, where the value counts
  the devices.
  """
  @spec platforms() :: {:ok, map()} | {:error, :backend_unavailable}
  def platforms do
    if available?() do
      {:ok, EXLA.Client.get_supported_platforms()}
    else
      {:error, :backend_unavailable}
    end
  end

  @doc "True when XLA reports at least one CUDA device."
  @spec cuda?() :: boolean()
  def cuda? do
    case platforms() do
      {:ok, map} -> Map.get(map, :cuda, 0) > 0
      {:error, :backend_unavailable} -> false
    end
  end

  @doc """
  Describes the compute backend.

  Returns `{:ok, info}` when EXLA is present, or
  `{:error, :backend_unavailable}` when it did not build.
  """
  @spec info() :: {:ok, map()} | {:error, :backend_unavailable}
  def info do
    if available?() do
      {:ok,
       %{
         backend: "EXLA",
         accelerator: if(cuda?(), do: "cuda", else: "host"),
         platforms: describe_platforms(),
         nx_version: application_version(:nx),
         exla_version: application_version(:exla),
         xla_target: System.get_env("XLA_TARGET", "unset (host only)")
       }}
    else
      {:error, :backend_unavailable}
    end
  end

  @doc """
  Runs a small tensor op through the backend.

  This proves XLA compiled a graph and executed it. It is a health
  check for the accelerator before a real model runs.

  A backend that loads and then fails this crashes the caller. That is
  the intent.
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
