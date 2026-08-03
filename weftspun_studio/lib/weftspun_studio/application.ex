defmodule WeftspunStudio.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = []
    opts = [strategy: :one_for_one, name: WeftspunStudio.Supervisor]
    {:ok, pid} = Supervisor.start_link(children, opts)

    if release?() do
      argv() |> WeftspunStudio.CLI.main() |> System.halt()
    end

    {:ok, pid}
  end

  # A Burrito binary does not populate System.argv/0. RFD 0019 records
  # this constraint.
  defp argv do
    if Code.ensure_loaded?(Burrito.Util.Args) do
      Burrito.Util.Args.argv()
    else
      System.argv()
    end
  end

  defp release?, do: System.get_env("RELEASE_NAME") != nil
end
