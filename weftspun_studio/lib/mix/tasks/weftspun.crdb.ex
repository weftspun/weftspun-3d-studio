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
    # The priv directory itself, and not priv/cockroach. install/2
    # appends "cockroach" on its own, and bin/1 reads back from
    # priv/cockroach/. Passing the deeper path nested it twice, and
    # the lookup then found nothing.
    priv = Application.app_dir(:weftspun_studio, "priv")

    case CockroachLocal.Provision.install(target(), priv) do
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

  @doc """
  The `{os, cpu}` pair `CockroachLocal.Provision` keys its assets by.

  This is not `:os.type/0`. That returns `{os_family, os_name}`, such
  as `{:win32, :nt}` or `{:unix, :linux}`, and the asset map is keyed
  `{:windows, :x86_64}`. The two shapes never matched, thus install
  answered `:unsupported_target` on every host.

  The V-Sekai release carries a Windows build. RFD 0020 selects it.
  """
  @spec target() :: {atom(), atom()}
  def target, do: {os_name(), cpu()}

  defp os_name do
    case :os.type() do
      {:win32, _name} -> :windows
      {:unix, :darwin} -> :darwin
      {:unix, name} -> name
    end
  end

  # The architecture string leads with the CPU, such as
  # "x86_64-pc-windows" or "aarch64-apple-darwin".
  defp cpu do
    :system_architecture
    |> :erlang.system_info()
    |> to_string()
    |> String.split("-")
    |> hd()
    |> normalise_cpu()
  end

  defp normalise_cpu("amd64"), do: :x86_64
  defp normalise_cpu("arm64"), do: :aarch64
  defp normalise_cpu(other), do: String.to_atom(other)

  defp opts do
    [
      port: @port,
      data_dir: @data_dir,
      priv_app: :weftspun_studio
    ]
  end
end
