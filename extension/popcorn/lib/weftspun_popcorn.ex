defmodule WeftspunPopcorn do
  @moduledoc """
  The minimal test, run inside the editor.

  It answers one question: does a real Elixir VM start in the webview
  and run this project's code? Everything here executes in AtomVM,
  compiled to WebAssembly by Popcorn.

  The checks are deterministic, so a wrong answer means the VM is
  wrong, and not that the test is flaky.
  """
  use GenServer

  @process_name :main

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: @process_name)
  end

  @impl true
  def init(_arg) do
    report(run_checks())
    Popcorn.Wasm.ready()
    :ignore
  end

  @doc """
  Runs every check and returns them as a list.

  Each entry is `{name, passed?, detail}`. This function is pure, so
  the same list can run outside the browser under `mix test`.
  """
  def run_checks do
    [
      check("arithmetic", Enum.sum(1..100), 5050),
      check("binaries", String.upcase("weftspun"), "WEFTSPUN"),
      check("pattern match", {:ok, [1, 2, 3]} |> elem(1) |> length(), 3),
      check("map update", %{traits: 1} |> Map.update!(:traits, &(&1 + 1)) |> Map.get(:traits), 2),
      check("processes", spawn_and_reply(), :pong),
      check("reduce", Enum.reduce([1, 2, 3, 4], 1, &(&1 * &2)), 24)
    ]
  end

  defp check(name, actual, expected) do
    {name, actual == expected, "#{inspect(actual)} == #{inspect(expected)}"}
  end

  # A real message round trip, which is the part a plain expression
  # would not prove. AtomVM must schedule a second process for this.
  defp spawn_and_reply do
    parent = self()
    spawn(fn -> send(parent, :pong) end)

    receive do
      :pong -> :pong
    after
      1000 -> :timeout
    end
  end

  defp report(checks) do
    passed = Enum.count(checks, fn {_, ok?, _} -> ok? end)
    total = length(checks)

    rows =
      checks
      |> Enum.map(fn {name, ok?, detail} ->
        ~s({"name":"#{name}","passed":#{ok?},"detail":"#{escape(detail)}"})
      end)
      |> Enum.join(",")

    IO.puts("weftspun minimal test: #{passed}/#{total} passed")

    # Popcorn evaluates this in a hidden iframe, and that iframe holds
    # the VM. `srcdoc` keeps it on the parent origin, thus the panel is
    # reachable through `window.parent`. Writing to `document` here
    # would only change the hidden frame, and nobody would see it.
    Popcorn.Wasm.run_js("""
    () => {
      window.parent.weftspunReport({
        elixir: "#{System.version()}",
        otp: "#{:erlang.system_info(:otp_release)}",
        machine: "#{:erlang.system_info(:machine)}",
        passed: #{passed},
        total: #{total},
        checks: [#{rows}]
      });
    }
    """)
  end

  defp escape(text) do
    text
    |> String.replace("\\", "\\\\")
    |> String.replace("\"", "\\\"")
  end
end
