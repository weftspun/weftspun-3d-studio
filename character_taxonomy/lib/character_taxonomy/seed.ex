# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule CharacterTaxonomy.Seed do
  @moduledoc """
  A first-boot seed for RFD 0065's taxonomy, before the RFD 0064
  dataset run populates it for real.

  These values are a starting point, not a fixed list. RFD 0065's
  Decision names the point of this schema: the taxonomy comes from
  the training data, not from preconceived categories. Every entry
  here is a mint through the normal `resolve_or_mint` path, and the
  15,000-row run replaces this list's weight in practice, though it
  never replaces the mechanism.
  """

  @spec categories() :: %{String.t() => [String.t()]}
  def categories do
    %{
      "hair_color" => ~w(black brown blonde red silver blue pink white),
      "eye_color" => ~w(black brown blue green violet amber red),
      "pose" => ~w(standing sitting action portrait),
      "clothing" => ~w(school_uniform casual fantasy_armor swimsuit yukata)
    }
  end

  @spec numerics() :: %{String.t() => [number()]}
  def numerics do
    %{
      "height_cm" => [140, 150, 160, 170, 180],
      "age" => [12, 16, 18, 22, 28]
    }
  end
end
