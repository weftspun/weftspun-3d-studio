defmodule WeftspunStudio.ComputeTest do
  use ExUnit.Case, async: false

  alias WeftspunStudio.Compute

  test "the EXLA backend is available" do
    assert Compute.available?()
  end

  @tag :cuda
  test "XLA reports a CUDA device" do
    assert {:ok, platforms} = Compute.platforms()
    assert Map.get(platforms, :cuda, 0) > 0, "expected a CUDA device, got: #{inspect(platforms)}"
    assert Compute.cuda?()
  end

  test "info names EXLA and reports an accelerator" do
    assert {:ok, info} = Compute.info()
    assert info.backend == "EXLA"
    assert info.accelerator in ["cuda", "host"]
  end

  @tag :cuda
  test "the accelerator is cuda when the runtime is provisioned" do
    assert {:ok, %{accelerator: "cuda"}} = Compute.info()
  end

  test "a graph compiles and runs on the accelerator" do
    assert {:ok, result} = Compute.smoke_test()
    assert_in_delta result, 32.0, 0.0001
  end
end
