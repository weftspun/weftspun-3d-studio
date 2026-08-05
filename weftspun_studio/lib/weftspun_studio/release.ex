# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule WeftspunStudio.Release do
  @moduledoc """
  Database tasks for a packaged binary.

  A Burrito release carries no Mix, so `mix ecto.migrate` cannot run
  against it. These functions do the same work from the release.
  """

  @app :weftspun_studio

  @doc """
  Creates the database if it does not exist yet.

  A fresh CockroachDB node (RFD 0058's `weftspun-crdb` container, on
  its first boot) holds no `weftspun_studio` database, and
  `Ecto.Migrator.with_repo/2` connects to a database rather than
  creating one — `migrate/0` alone errors with `invalid_catalog_name`
  against an empty cluster. `storage_up/1` is idempotent, so calling
  this every boot is safe.
  """
  @spec create() :: :ok
  def create do
    load()

    for repo <- repos() do
      case repo.__adapter__().storage_up(repo.config()) do
        :ok -> :ok
        {:error, :already_up} -> :ok
        {:error, reason} -> raise "cannot create database for #{inspect(repo)}: #{inspect(reason)}"
      end
    end

    :ok
  end

  @doc "Applies every migration that the database has not run."
  @spec migrate() :: :ok
  def migrate do
    load()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end

    :ok
  end

  @doc "Rolls one repository back to the given version."
  @spec rollback(module(), integer()) :: :ok
  def rollback(repo, version) do
    load()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
    :ok
  end

  @doc """
  Writes the RFD 0016 inventory into the database.

  The repository must already be up, so the caller runs `migrate/0`
  first.
  """
  @spec seed() :: {:ok, non_neg_integer()}
  def seed do
    load()

    {:ok, count, _} =
      Ecto.Migrator.with_repo(WeftspunStudio.Repo, fn _repo ->
        {:ok, count} = WeftspunStudio.Adapters.EctoFactStore.seed()
        count
      end)

    {:ok, count}
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load do
    Application.load(@app)
  end
end
