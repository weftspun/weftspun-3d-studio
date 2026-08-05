defmodule WeftspunStudio.ComputeTest do
  @moduledoc """
  EXLA is a backend for Nx, and not a requirement of it. `mix.exs`
  skips the dependency where XLA publishes no archive, and Windows is
  such a host.

  These tests therefore split. The absence path runs everywhere. The
  presence path is tagged `:exla` and skips where the backend is
  absent, so a Windows run reports a skip and not a failure.

      mix test --include exla
  """

  use ExUnit.Case, async: false

  alias WeftspunStudio.Compute

  # `Compute.available?/0` reads Code.ensure_loaded?(EXLA), thus this
  # decides at run time and not at compile time.
  @moduletag exla: Compute.available?()

  setup_all do
    unless Compute.available?() do
      IO.puts("\n  EXLA is absent on this host, thus the backend tests skip.")
    end

    :ok
  end

  describe "without the backend" do
    @describetag exla: false

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
    @describetag exla: true

    test "the EXLA backend is available" do
      assert Compute.available?()
    end

    test "info names EXLA and reports an accelerator" do
      assert {:ok, info} = Compute.info()
      assert info.backend == "EXLA"
      assert info.accelerator in ["cuda", "host"]
    end

    test "a graph compiles and runs on the accelerator" do
      assert {:ok, result} = Compute.smoke_test()
      assert_in_delta result, 32.0, 0.0001
    end

    @tag :cuda
    test "XLA reports a CUDA device" do
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
