# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule WeftspunStudio.FactVector do
  @moduledoc """
  Encodes a catalog fact as one holographic vector.

  The phase algebra lives in the `hrr` library, which the weftspun
  repositories share. This module holds only the part that knows what
  a catalog fact is: which roles it has, and how a free-text query
  probes them.

  A fact binds each part to its role, then bundles the parts:

      bundle([
        bind(role(:id), atom(fact_id)),
        bind(role(:category), atom(category)),
        bind(role(:tag), bundle(atoms(tags)))
      ])

  Unrelated atoms in a high dimension are near orthogonal, so the
  bundle stays similar to each part while the parts stay apart. That
  property carries the retrieval, and the store needs no separate
  index.

  The tags bundle before they bind, so a fact with many tags does not
  outweigh its own id.

  RFD 0021 records the move from the earlier local implementation.
  """

  @default_dim 1024

  @doc """
  The default vector width.

  A phase vector holds f64 values, so one vector takes `dim * 8`
  bytes. At 1024 a stored row takes 8 kilobytes, and the capacity of
  `√1024 = 32` items far exceeds the four parts a fact bundles.
  """
  @spec default_dim() :: pos_integer()
  def default_dim, do: @default_dim

  @doc "The atom for a structural role, such as `:id` or `:category`."
  @spec role(atom(), pos_integer()) :: Nx.Tensor.t()
  def role(name, dim \\ @default_dim), do: HRR.encode_atom("role:" <> Atom.to_string(name), dim)

  @doc "Encodes one catalog fact as a single vector."
  @spec encode(map(), pos_integer()) :: Nx.Tensor.t()
  def encode(fact, dim \\ @default_dim) do
    parts = [
      HRR.bind(role(:id, dim), HRR.encode_atom(fact.fact_id, dim)),
      HRR.bind(role(:category, dim), HRR.encode_atom(fact.category, dim))
    ]

    parts =
      case Map.get(fact, :tags) || [] do
        [] ->
          parts

        tags ->
          tags = Enum.map(tags, &HRR.encode_atom(&1, dim))
          parts ++ [HRR.bind(role(:tag, dim), HRR.bundle(tags))]
      end

    HRR.bundle(parts)
  end

  @doc """
  Recovers the symbol bound to one role of an encoded fact.

  Returns `{token, score}` for the nearest symbol in the codebook, or
  `nil` when the codebook is empty.
  """
  @spec probe(Nx.Tensor.t(), atom(), HRR.Cleanup.codebook(), pos_integer()) ::
          {String.t(), float()} | nil
  def probe(vector, role_name, codebook, dim \\ @default_dim) do
    vector
    |> HRR.unbind(role(role_name, dim))
    |> HRR.Cleanup.nearest(codebook)
  end

  @doc """
  Every symbol these facts can resolve to.

  A probe may ask for any role, so the codebook carries the ids, the
  categories, and the tags together.
  """
  @spec codebook([map()], pos_integer()) :: HRR.Cleanup.codebook()
  def codebook(facts, dim \\ @default_dim) do
    facts
    |> Enum.flat_map(fn f -> [f.fact_id, f.category | Map.get(f, :tags) || []] end)
    |> HRR.Cleanup.codebook(dim)
  end

  @doc """
  Encodes a free-text query as a probe vector.

  A term may name an id, a category, or a tag, and the query does not
  say which. The probe therefore binds each term to all three roles
  and bundles the result, so a fact matches on whichever role holds
  the term.
  """
  @spec query(String.t(), pos_integer()) :: Nx.Tensor.t()
  def query(text, dim \\ @default_dim) do
    case terms(text) do
      [] ->
        HRR.encode_atom("__weftspun_empty_query__", dim)

      terms ->
        terms
        |> Enum.flat_map(fn term ->
          atom = HRR.encode_atom(term, dim)

          [
            HRR.bind(role(:id, dim), atom),
            HRR.bind(role(:category, dim), atom),
            HRR.bind(role(:tag, dim), atom)
          ]
        end)
        |> HRR.bundle()
    end
  end

  defp terms(text) do
    text
    |> String.downcase()
    |> String.split(~r/[^a-z0-9_.]+/u, trim: true)
  end
end
