defmodule WeftspunPopcorn do
  @moduledoc """
  The minimal test, run inside the editor.

  It answers two questions. Does a real Elixir VM start in the panel?
  Does WGSL that Elixir generated run on the GPU and come back right?

  JavaScript drives the exchange, because `Popcorn.Wasm.run_js/3` is
  synchronous and every WebGPU call is asynchronous. Elixir cannot
  await a dispatch, thus the page calls in twice. It asks for the plan,
  runs the kernels, and sends the buffers back for a verdict.

  Elixir keeps what matters: it writes the WGSL, it computes the
  expected values, and it decides pass or fail. WebGPU only executes.
  """
  use GenServer

  import Popcorn.Wasm, only: [is_wasm_message: 1]
  alias Popcorn.Wasm
  alias WeftspunPopcorn.Wgsl

  @process_name :main

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: @process_name)
  end

  @impl GenServer
  def init(_arg) do
    Wasm.ready(@process_name)
    {:ok, %{}}
  end

  @impl GenServer
  def handle_info(raw, state) when is_wasm_message(raw) do
    {:noreply, Wasm.handle_message!(raw, &handle_wasm(&1, state))}
  end

  # The checks that need no GPU. These prove the VM itself.
  defp handle_wasm({:wasm_call, ["vm_checks"]}, state) do
    checks =
      Enum.map(vm_checks(), fn {name, ok?, detail} ->
        %{"name" => name, "passed" => ok?, "detail" => detail}
      end)

    report = %{
      "elixir" => System.version(),
      "otp" => to_string(:erlang.system_info(:otp_release)),
      "machine" => to_string(:erlang.system_info(:machine)),
      "checks" => checks
    }

    {:resolve, report, state}
  end

  # The WGSL, the inputs, and the length of each answer. The expected
  # values stay here, because the page must not be able to mark its own
  # homework.
  defp handle_wasm({:wasm_call, ["gpu_plan"]}, state) do
    jobs = Wgsl.jobs()

    plan =
      Enum.map(jobs, fn job ->
        %{
          "name" => job.name,
          "source" => job.source,
          "buffers" => job.buffers,
          "length" => job.length
        }
      end)

    expected = Map.new(jobs, &{&1.name, &1.expected})
    {:resolve, plan, Map.put(state, :expected, expected)}
  end

  defp handle_wasm({:wasm_call, ["gpu_verify", name, actual]}, state) do
    case get_in(state, [:expected, name]) do
      nil ->
        {:resolve, %{"passed" => false, "detail" => "no expected values for #{name}"}, state}

      expected ->
        {ok?, detail} = Wgsl.compare(expected, actual)
        {:resolve, %{"passed" => ok?, "detail" => detail}, state}
    end
  end

  @doc """
  Checks that need no GPU.

  Each entry is `{name, passed?, detail}`. The list is pure, thus it
  runs the same way outside a browser.
  """
  def vm_checks do
    [
      check("arithmetic", Enum.sum(1..100), 5050),
      check("binaries", String.upcase("weftspun"), "WEFTSPUN"),
      check("processes", spawn_and_reply(), :pong),
      check("wgsl codegen", wgsl_declares_workgroup?(), true)
    ]
  end

  defp check(name, actual, expected) do
    {name, actual == expected, "#{inspect(actual)} == #{inspect(expected)}"}
  end

  # A real message round trip. A plain expression would not prove that
  # AtomVM schedules a second process.
  defp spawn_and_reply do
    parent = self()
    spawn(fn -> send(parent, :pong) end)

    receive do
      :pong -> :pong
    after
      1000 -> :timeout
    end
  end

  # Does Nx run on AtomVM at all? This is the assumption a WGSL backend
  # for Nx rests on, thus it is worth a check and not a hope.
  defp nx_sum do
    try do
      Nx.tensor([1, 2, 3]) |> Nx.sum() |> Nx.to_number()
    rescue
      e -> "raised: #{inspect(e.__struct__)}"
    catch
      kind, value -> "threw: #{inspect(kind)} #{inspect(value)}"
    end
  end

  defp nx_add do
    try do
      Nx.add(Nx.tensor([1, 2, 3]), Nx.tensor([4, 5, 6])) |> Nx.to_flat_list()
    rescue
      e -> "raised: #{inspect(e.__struct__)}"
    catch
      kind, value -> "threw: #{inspect(kind)} #{inspect(value)}"
    end
  end

  defp wgsl_declares_workgroup? do
    String.contains?(
      Wgsl.binary("probe", "+").source,
      "@workgroup_size(#{Wgsl.workgroup_size()})"
    )
  end
end
