# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule Mix.Tasks.Weftspun.Crdb do
  @shortdoc "Runs the local CockroachDB host in the foreground"

  @moduledoc """
  Runs the CockroachDB node the studio core develops against.

  The `cockroach_local` library owns the host lifecycle. It resolves
  the binary from `COCKROACH_BIN`, then `priv/cockroach/`, then the
  path. `mix weftspun.crdb install` fetches the V-Sekai 22.1 build
  that RFD 0020 selects, so no manual download is necessary.

      mix weftspun.crdb install   # fetch the binary into priv/cockroach
      mix weftspun.crdb           # run a node in the foreground
      mix weftspun.crdb path      # print the binary this project uses

  The node listens on 127.0.0.1:26257 and stores data under `.crdb`,
  which stays out of version control. Stop it with Ctrl-C.

  This runs an insecure node, so the `root` user needs no password.
  Use it on a developer machine only.
  """

  use Mix.Task

  @data_dir ".crdb/data"
  @port 26_257

  @impl true
  def run(["install" | _]) do
    priv = Path.join(Application.app_dir(:weftspun_studio), "priv/cockroach")

    case CockroachLocal.Provision.install(:os.type(), priv) do
      {:ok, path} -> Mix.shell().info("installed #{path}")
      {:error, reason} -> Mix.raise("cannot install cockroach: #{inspect(reason)}")
    end
  end

  def run(["path" | _]) do
    case CockroachLocal.bin(opts()) do
      {:ok, path} -> Mix.shell().info(path)
      {:error, reason} -> Mix.raise(reason)
    end
  end

  def run(_args) do
    Mix.shell().info("cockroach on 127.0.0.1:#{@port}, data in #{@data_dir}")

    case CockroachLocal.run_foreground(opts()) do
      {:ok, _} -> :ok
      {:error, message, status} -> Mix.raise("#{message} (status #{status})")
    end
  end

  defp opts do
    [
      port: @port,
      data_dir: @data_dir,
      priv_app: :weftspun_studio
    ]
  end
end
