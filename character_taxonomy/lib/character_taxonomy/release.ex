# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule CharacterTaxonomy.Release do
  @moduledoc """
  Database tasks for a packaged release, in `WeftspunStudio.Release`'s
  own style. A release carries no Mix, so `mix ecto.migrate` cannot
  run against it.
  """

  @app :character_taxonomy

  @doc "Creates the database if it does not exist yet. Idempotent."
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

  @doc """
  Applies every migration that the database has not run.

  This includes `..._seed_taxonomy.exs`, so a first boot against an
  empty CockroachDB node ends with the seed loaded, and a later boot
  against the same node runs no migration twice.
  """
  @spec migrate() :: :ok
  def migrate do
    load()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end

    :ok
  end

  defp repos, do: Application.fetch_env!(@app, :ecto_repos)
  defp load, do: Application.load(@app)
end
