# SPDX-License-Identifier: MIT

defmodule WeftspunCMS.Core.Ports.CatalogSource do
  @moduledoc """
  The port for the model catalog.

  RFD 0022 introduced this port in the client. It answers one question:
  which models exist, and what does each one cost.

  The cost matters here. RFD 0027 caps what may stay resident, and a
  planner cannot respect a budget it cannot read.
  """

  alias WeftspunCMS.Core.Domain.Model

  @typedoc "An API feature key, such as `image_to_textured_mesh`."
  @type feature :: String.t()

  @doc "Every model the catalog knows."
  @callback list_models() :: {:ok, [Model.t()]} | {:error, String.t()}

  @doc "The models that serve one feature, most preferred first."
  @callback list_models_for_feature(feature()) :: {:ok, [Model.t()]} | {:error, String.t()}

  @doc "One model by its id."
  @callback fetch_model(String.t()) :: {:ok, Model.t()} | {:error, :not_found}
end
