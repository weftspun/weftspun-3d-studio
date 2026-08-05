# SPDX-License-Identifier: MIT

defmodule WeftspunCMS.Composition do
  @moduledoc """
  The composition root. The only module that picks an adapter.

  RFD 0023 puts this outside the core. The root must know every side,
  and the core may not reach a chain, thus the root cannot live inside
  the core.

  Every adapter comes from config, and each one has a headless default.
  A deployment with no chain, no planner, and no store still starts.
  """

  alias WeftspunCMS.Content

  alias WeftspunCMS.Core.Adapters.{
    NullOwnedAssetSource,
    StaticCatalogSource,
    TaskweftPlanner
  }

  @doc """
  Builds the content API from config.

  The defaults are the headless case. `NullOwnedAssetSource` reports
  `enabled?` as false and answers with empty lists, thus content serves
  with no wallet and no chain library.
  """
  @spec build(keyword()) :: Content.t()
  def build(overrides \\ []) do
    %Content{
      planner: adapter(overrides, :planner, TaskweftPlanner),
      catalog: adapter(overrides, :catalog, StaticCatalogSource),
      owned_assets: adapter(overrides, :owned_assets, NullOwnedAssetSource),
      jobs: adapter(overrides, :jobs, nil),
      assets: adapter(overrides, :assets, nil)
    }
  end

  # An override wins, then config, then the default. The override is
  # what a test uses to inject a Mox mock.
  defp adapter(overrides, key, default) do
    Keyword.get(overrides, key) ||
      Application.get_env(:weftspun_cms, key) ||
      default
  end
end
