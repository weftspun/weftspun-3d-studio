defmodule WeftspunStudio.CLI do
  @moduledoc """
  Command line entry point for the Burrito binary.

  A Burrito release must read `Burrito.Util.Args.argv/0`. The wrapped
  binary does not populate `System.argv/0`.
  """

  alias WeftspunStudio.{Compute, Inventory, JsCatalog, Model}

  @usage """
  weftspun - studio core (RFD 0019)

  USAGE
      weftspun models list [--group GROUP] [--json]
      weftspun models verify [--catalog PATH]
      weftspun compute info
      weftspun db create
      weftspun db migrate
      weftspun db seed
      weftspun db status
      weftspun version

  COMMANDS
      models list      Print the model inventory from RFD 0016.
      models verify    Compare the inventory against the client catalog.
      compute info     Report the EXLA backend state.
      db create        Create the database if it does not exist yet.
      db migrate       Apply every pending database migration.
      db seed          Write the RFD 0016 inventory into the database.
      db status        Report the database connection and the row count.
      version          Print the version.

  OPTIONS
      --group GROUP    core | environment | splat | legacy | component
      --json           Print JSON instead of a table.
      --catalog PATH   Path to aiModelsCatalog.js.
  """

  @doc "Runs one command and returns the exit status."
  @spec main([String.t()]) :: 0 | 1
  def main(argv)

  def main(["models", "list" | rest]), do: models_list(rest)
  def main(["models", "verify" | rest]), do: models_verify(rest)
  def main(["compute", "info" | _rest]), do: compute_info()
  def main(["db", "create" | _rest]), do: db_create()
  def main(["db", "migrate" | _rest]), do: db_migrate()
  def main(["db", "seed" | _rest]), do: db_seed()
  def main(["db", "status" | _rest]), do: db_status()
  def main(["version" | _rest]), do: puts_ok(version())
  def main([]), do: puts_ok(@usage)
  def main(["help" | _]), do: puts_ok(@usage)
  def main(["--help" | _]), do: puts_ok(@usage)

  def main(other) do
    IO.puts(:stderr, "unknown command: #{Enum.join(other, " ")}\n")
    IO.puts(:stderr, @usage)
    1
  end

  @doc "The application version."
  @spec version() :: String.t()
  def version do
    case Application.spec(:weftspun_studio, :vsn) do
      nil -> "dev"
      vsn -> List.to_string(vsn)
    end
  end

  defp models_list(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [group: :string, json: :boolean])

    models =
      case opts[:group] do
        nil -> Inventory.all()
        group -> Enum.filter(Inventory.all(), &(Atom.to_string(&1.group) == group))
      end

    cond do
      models == [] and opts[:group] != nil ->
        IO.puts(:stderr, "no models in group: #{opts[:group]}")
        1

      opts[:json] ->
        models
        |> Enum.map(&Map.from_struct/1)
        |> Jason.encode!(pretty: true)
        |> puts_ok()

      true ->
        models |> render_table() |> puts_ok()
    end
  end

  defp models_verify(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [catalog: :string])
    path = opts[:catalog] || JsCatalog.default_path()

    case JsCatalog.diff(path) do
      {:ok, %{only_in_elixir: [], only_in_js: [], both: both}} ->
        puts_ok("parity ok - #{length(both)} shared model ids")

      {:ok, diff} ->
        IO.puts("parity FAILED against #{path}")
        report_side("only in the Elixir inventory", diff.only_in_elixir)
        report_side("only in the client catalog", diff.only_in_js)
        IO.puts("\nshared: #{length(diff.both)}")
        1

      {:error, reason} ->
        IO.puts(:stderr, "cannot read #{path}: #{inspect(reason)}")
        1
    end
  end

  defp compute_info do
    case Compute.info() do
      {:ok, info} ->
        info
        |> Enum.map_join("\n", fn {k, v} -> "#{k}: #{v}" end)
        |> puts_ok()

      {:error, :backend_unavailable} ->
        IO.puts(:stderr, """
        EXLA is not available.

        The backend needs the EXLA dependency. Build it with
        XLA_TARGET=cuda12 for the NVIDIA client. The inventory
        commands still work without it.
        """)

        1
    end
  end

  # No rescue. Release.migrate/0 already matches {:ok, _, _}, thus an
  # unreachable database crashes there and the stacktrace names the
  # real fault. A rescue here reformatted that into one message and
  # threw the cause away.
  defp db_create do
    WeftspunStudio.Release.create()
    puts_ok("database ready")
  end

  defp db_migrate do
    WeftspunStudio.Release.migrate()
    puts_ok("migrations applied")
  end

  defp db_seed do
    {:ok, count} = WeftspunStudio.Release.seed()
    puts_ok("seeded #{count} facts from the RFD 0016 inventory")
  end

  defp db_status do
    alias WeftspunStudio.{Facts.Fact, Repo}

    if Repo.up?() do
      config = Repo.config()

      """
      connection: up
      host: #{config[:hostname]}:#{config[:port]}
      database: #{config[:database]}
      facts: #{Repo.aggregate(Fact, :count)}
      """
      |> puts_ok()
    else
      IO.puts(:stderr, "connection: down")
      1
    end
  end

  defp report_side(_label, []), do: :ok

  defp report_side(label, ids) do
    IO.puts("\n#{label}:")
    Enum.each(ids, &IO.puts("  #{&1}"))
  end

  defp render_table(models) do
    rows =
      Enum.map(models, fn %Model{} = m ->
        [m.id, type_label(m.type), m.task, runs_on_label(m.runs_on), Atom.to_string(m.status)]
      end)

    header = ["Model id", "Type", "Task", "Runs on", "Status"]
    widths = column_widths([header | rows])

    [header | rows]
    |> Enum.map_join("\n", &render_row(&1, widths))
  end

  defp column_widths(rows) do
    rows
    |> Enum.zip_with(fn column -> column |> Enum.map(&String.length/1) |> Enum.max() end)
  end

  defp render_row(cells, widths) do
    cells
    |> Enum.zip(widths)
    |> Enum.map_join("  ", fn {cell, width} -> String.pad_trailing(cell, width) end)
    |> String.trim_trailing()
  end

  defp type_label(:deep_learning), do: "deep learning"
  defp type_label(:geometric), do: "geometric"

  defp runs_on_label(:dgx_api), do: "DGX API"
  defp runs_on_label(:local), do: "local"
  defp runs_on_label(:external), do: "external"

  defp puts_ok(text) do
    IO.puts(text)
    0
  end
end
