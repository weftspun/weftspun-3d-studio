defmodule WeftspunStudio.Compute do
  @moduledoc """
  Tensor backend for the studio core.

  RFD 0019 selects EXLA on CUDA. EXLA compiles `Nx.Defn` graphs with
  Google XLA and runs them on an NVIDIA device. Build the dependency
  with `XLA_TARGET=cuda12` so the precompiled binary carries the CUDA
  client.

  A machine without a CUDA device still runs. EXLA falls back to the
  host client. Every function here reports the state instead of
  raising, because the inventory commands must work without a GPU.
  """

  @doc "True when the EXLA backend compiled and loaded."
  @spec available?() :: boolean()
  def available?, do: Code.ensure_loaded?(EXLA)

  @doc """
  Platforms the local XLA build supports.

  Returns a map such as `%{host: 1, cuda: 1}`, where the value counts
  the devices. Returns `{:error, reason}` when the query fails.
  """
  @spec platforms() :: {:ok, map()} | {:error, term()}
  def platforms do
    if available?() do
      try do
        {:ok, EXLA.Client.get_supported_platforms()}
      rescue
        error -> {:error, error}
      end
    else
      {:error, :backend_unavailable}
    end
  end

  @doc "True when XLA reports at least one CUDA device."
  @spec cuda?() :: boolean()
  def cuda? do
    case platforms() do
      {:ok, map} -> Map.get(map, :cuda, 0) > 0
      _ -> false
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
  """
  @spec smoke_test() :: {:ok, number()} | {:error, :backend_unavailable} | {:error, term()}
  def smoke_test do
    if available?() do
      try do
        a = Nx.tensor([1.0, 2.0, 3.0], type: :f32)
        b = Nx.tensor([4.0, 5.0, 6.0], type: :f32)

        {:ok, a |> Nx.multiply(b) |> Nx.sum() |> Nx.to_number()}
      rescue
        error -> {:error, error}
      end
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
