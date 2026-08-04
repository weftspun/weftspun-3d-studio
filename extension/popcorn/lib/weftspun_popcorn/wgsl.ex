defmodule WeftspunPopcorn.Wgsl do
  @moduledoc """
  Generates WGSL compute kernels from Elixir.

  The kernels here are textbook and naive. One invocation handles one
  element, the workgroup size is fixed, and nothing is tiled, staged,
  or vectorized. That is deliberate. It separates the hard part of the
  orchestration, which is Elixir to WebAssembly to WebGPU and back,
  from the hard part of graphics work, which is a fast kernel.

  A faster kernel is a later change to this module alone. The pipeline
  around it does not move when the kernel does.
  """

  @workgroup_size 64

  @doc "The workgroup size every kernel here declares."
  def workgroup_size, do: @workgroup_size

  @doc """
  A kernel that reads two buffers and writes one.

  `op` names a WGSL infix operator, such as `+` or `*`.
  """
  def binary(name, op) do
    %{
      name: name,
      inputs: 2,
      source: """
      @group(0) @binding(0) var<storage, read> a: array<f32>;
      @group(0) @binding(1) var<storage, read> b: array<f32>;
      @group(0) @binding(2) var<storage, read_write> out: array<f32>;

      @compute @workgroup_size(#{@workgroup_size})
      fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let i = gid.x;
        if (i >= arrayLength(&out)) { return; }
        out[i] = a[i] #{op} b[i];
      }
      """
    }
  end

  @doc """
  A kernel that reads one buffer and writes one.

  `expr` is WGSL that uses `x` as the element.
  """
  def unary(name, expr) do
    %{
      name: name,
      inputs: 1,
      source: """
      @group(0) @binding(0) var<storage, read> a: array<f32>;
      @group(0) @binding(1) var<storage, read_write> out: array<f32>;

      @compute @workgroup_size(#{@workgroup_size})
      fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let i = gid.x;
        if (i >= arrayLength(&out)) { return; }
        let x = a[i];
        out[i] = #{expr};
      }
      """
    }
  end

  @doc """
  The jobs the panel runs, each with its inputs and the answer Elixir
  expects.

  Elixir computes the expected values, thus the check compares the GPU
  with the BEAM and not with a constant somebody typed.
  """
  def jobs do
    a = Enum.map(1..256, &(&1 * 1.0))
    b = Enum.map(1..256, &(&1 * 0.5))
    signed = Enum.map(-128..127, &(&1 * 1.0))

    [
      job(binary("vector add", "+"), [a, b], zip_with(a, b, &(&1 + &2))),
      job(binary("vector multiply", "*"), [a, b], zip_with(a, b, &(&1 * &2))),
      job(unary("relu", "max(x, 0.0)"), [signed], Enum.map(signed, &max(&1, 0.0))),
      job(unary("scale by 3", "x * 3.0"), [a], Enum.map(a, &(&1 * 3.0)))
    ]
  end

  defp job(kernel, inputs, expected) do
    kernel
    |> Map.put(:buffers, inputs)
    |> Map.put(:expected, expected)
    |> Map.put(:length, length(expected))
  end

  defp zip_with(a, b, fun), do: Enum.zip_with(a, b, fun)

  @doc """
  Compares what the GPU returned with what Elixir expected.

  The tolerance is for f32. The GPU holds 32 bit floats, and the BEAM
  holds 64 bit floats, thus an exact match is the wrong test.
  """
  def compare(expected, actual, tolerance \\ 1.0e-5) do
    cond do
      length(actual) != length(expected) ->
        {false, "length #{length(actual)}, expected #{length(expected)}"}

      true ->
        worst =
          Enum.zip(expected, actual)
          |> Enum.map(fn {e, a} -> abs(e - a) end)
          |> Enum.max(fn -> 0.0 end)

        if worst <= tolerance do
          {true, "#{length(actual)} values, worst error #{format(worst)}"}
        else
          {false, "worst error #{format(worst)} is over #{tolerance}"}
        end
    end
  end

  defp format(number) when is_float(number), do: :erlang.float_to_binary(number, decimals: 9)
  defp format(number), do: to_string(number)
end
