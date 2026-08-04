defmodule WeftspunStudio.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # The RFD 0016 inventory seeds the fact store at boot.
    children =
      repo() ++
        [WeftspunStudio.FactStore] ++
        if serve?() do
          [{Bandit, plug: WeftspunStudio.Router, port: port()}]
        else
          []
        end

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

  # The inventory commands need no database, so a Burrito binary can
  # run `models list` on a host with no cluster. Set WEFTSPUN_DB=0 to
  # leave the pool out.
  defp repo do
    if System.get_env("WEFTSPUN_DB", "1") == "1" do
      [WeftspunStudio.Repo]
    else
      []
    end
  end

  # The HTTP surface stays off during tests, which call the router
  # directly through Plug.Test.
  defp serve?, do: System.get_env("WEFTSPUN_SERVE", "1") == "1" and Mix.env() != :test

  defp port, do: String.to_integer(System.get_env("WEFTSPUN_PORT", "4000"))
end
