defmodule WeftspunStudio.ComputeTest do
  @moduledoc """
  Torchx binds LibTorch, which ships for every host this project runs
  on. RFD 0019 first selected EXLA, and XLA publishes no Windows
  archive.

  The tests still split. The absence path guards a build where
  LibTorch did not fetch, and the presence path carries the tag that
  test_helper.exs excludes when the backend is missing.
  """

  use ExUnit.Case, async: false

  alias WeftspunStudio.Compute

  # `Compute.available?/0` reads Code.ensure_loaded?(Torchx), thus the
  # split decides at run time and not at compile time.
  @moduletag torchx: Compute.available?()

  setup_all do
    unless Compute.available?() do
      IO.puts("\n  EXLA is absent on this host, thus the backend tests skip.")
    end

    :ok
  end

  describe "without the backend" do
    @describetag torchx: false

    test "available? reports false, and does not raise" do
      refute Compute.available?()
    end

    test "info names the reason, so the CLI can print it" do
      assert {:error, :backend_unavailable} = Compute.info()
    end

    test "the smoke test reports the same reason" do
      assert {:error, :backend_unavailable} = Compute.smoke_test()
    end
  end

  describe "with the backend" do
    @describetag torchx: true

    test "the Torchx backend is available" do
      assert Compute.available?()
    end

    test "info names Torchx and reports an accelerator" do
      assert {:ok, info} = Compute.info()
      assert info.backend == "Torchx"
      assert info.accelerator in ["cuda", "cpu"]
    end

    test "a graph compiles and runs on the accelerator" do
      assert {:ok, result} = Compute.smoke_test()
      assert_in_delta result, 32.0, 0.0001
    end

    @tag :cuda
    test "LibTorch reports a CUDA device" do
      assert {:ok, platforms} = Compute.platforms()

      assert Map.get(platforms, :cuda, 0) > 0,
             "expected a CUDA device, got: #{inspect(platforms)}"

      assert Compute.cuda?()
    end

    @tag :cuda
    test "the accelerator is cuda when the runtime is provisioned" do
      assert {:ok, %{accelerator: "cuda"}} = Compute.info()
    end
  end
end
