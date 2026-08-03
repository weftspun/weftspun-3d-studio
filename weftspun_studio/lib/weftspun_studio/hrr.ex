# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule WeftspunStudio.Hrr do
  @moduledoc """
  Holographic Reduced Representations over Nx.

  A catalog fact becomes one fixed-width vector. The algebra holds the
  structure, so the store keeps no separate index:

    * `bind/2` ties a role to a filler with circular convolution.
    * `unbind/2` recovers the filler with the exact inverse.
    * `bundle/1` overlays several vectors into one.
    * `cleanup/2` snaps a noisy result back to a known symbol.

  Unrelated symbols in a high dimension are near orthogonal, so a
  bundle stays similar to each part while the parts stay apart. That
  property carries the retrieval.

  This matches the `hrr_vector` column in the hermes-agent
  holographic memory store. RFD 0019 records the choice.
  """

  import Nx.Defn

  @default_dim 1024

  @doc "The default vector width."
  @spec default_dim() :: pos_integer()
  def default_dim, do: @default_dim

  @doc """
  The vector for a symbol.

  The same token always gives the same vector, because the seed comes
  from a hash of the token. A store can therefore rebuild any vector
  without keeping it.

  The vector is unitary: its magnitude spectrum is flat. That makes
  `unbind/2` exact rather than approximate.
  """
  @spec vector(String.t(), pos_integer()) :: Nx.Tensor.t()
  def vector(token, dim \\ @default_dim) when is_binary(token) do
    seed =
      :crypto.hash(:sha256, token)
      |> binary_part(0, 8)
      |> :binary.decode_unsigned()
      |> rem(2_147_483_647)

    {v, _} = Nx.Random.normal(Nx.Random.key(seed), 0.0, 1.0, shape: {dim}, type: :f32)
    v |> unitary() |> normalize()
  end

  # Flattens the magnitude spectrum and keeps the phases. For such a
  # vector the involution is the exact inverse, not an approximation,
  # so bind and unbind compose without loss. The spectrum of a real
  # signal stays conjugate symmetric under this map, so the result
  # stays real.
  defp unitary(v) do
    spectrum = Nx.fft(v)
    magnitude = Nx.abs(spectrum)

    spectrum
    |> Nx.divide(Nx.max(magnitude, 1.0e-12))
    |> Nx.ifft()
    |> Nx.real()
  end

  @doc "The vector for a structural role, such as `:id` or `:category`."
  @spec role(atom(), pos_integer()) :: Nx.Tensor.t()
  def role(name, dim \\ @default_dim), do: vector("role:" <> Atom.to_string(name), dim)

  @doc "Euclidean norm."
  @spec norm(Nx.Tensor.t()) :: Nx.Tensor.t()
  defn norm(a), do: Nx.sqrt(Nx.sum(a * a))

  @doc "Scales a vector to unit length."
  @spec normalize(Nx.Tensor.t()) :: Nx.Tensor.t()
  defn normalize(a), do: a / Nx.max(norm(a), 1.0e-12)

  @doc """
  Binds two vectors with circular convolution.

  The result resembles neither input. Binding commutes.
  """
  @spec bind(Nx.Tensor.t(), Nx.Tensor.t()) :: Nx.Tensor.t()
  defn bind(a, b) do
    Nx.fft(a)
    |> Nx.multiply(Nx.fft(b))
    |> Nx.ifft()
    |> Nx.real()
  end

  @doc """
  The inverse of a vector.

  Element zero holds. The rest reverse, which conjugates the spectrum.
  For a unitary vector this is the exact inverse, so `unbind/2` loses
  nothing. `vector/2` returns unitary vectors.
  """
  @spec involution(Nx.Tensor.t()) :: Nx.Tensor.t()
  def involution(a) do
    dim = Nx.axis_size(a, 0)
    head = Nx.slice(a, [0], [1])
    tail = a |> Nx.slice([1], [dim - 1]) |> Nx.reverse()
    Nx.concatenate([head, tail])
  end

  @doc "Recovers the filler that `probe` was bound with."
  @spec unbind(Nx.Tensor.t(), Nx.Tensor.t()) :: Nx.Tensor.t()
  def unbind(trace, probe), do: bind(trace, involution(probe))

  @doc "Overlays vectors into one, then rescales to unit length."
  @spec bundle([Nx.Tensor.t()]) :: Nx.Tensor.t()
  def bundle([first | rest]) do
    rest |> Enum.reduce(first, &Nx.add(&2, &1)) |> normalize()
  end

  @doc "Cosine similarity."
  @spec similarity(Nx.Tensor.t(), Nx.Tensor.t()) :: Nx.Tensor.t()
  defn similarity(a, b), do: Nx.sum(normalize(a) * normalize(b))

  @doc """
  Snaps a noisy vector to the closest symbol in a codebook.

  Returns `{token, score}` for the best cosine match, or `nil` when
  the codebook is empty.
  """
  @spec cleanup(Nx.Tensor.t(), %{String.t() => Nx.Tensor.t()}) :: {String.t(), float()} | nil
  def cleanup(_probe, codebook) when map_size(codebook) == 0, do: nil

  def cleanup(probe, codebook) do
    codebook
    |> Enum.map(fn {token, vec} -> {token, Nx.to_number(similarity(probe, vec))} end)
    |> Enum.max_by(&elem(&1, 1))
  end

  @doc """
  Encodes one catalog fact as a single vector.

  Each part binds to its role, then the parts bundle together. The
  tags bundle first, so one tag does not outweigh the id.
  """
  @spec encode_fact(map(), pos_integer()) :: Nx.Tensor.t()
  def encode_fact(fact, dim \\ @default_dim) do
    parts = [
      bind(role(:id, dim), vector(fact.fact_id, dim)),
      bind(role(:category, dim), vector(fact.category, dim))
    ]

    parts =
      case fact.tags do
        [] -> parts
        tags -> parts ++ [bind(role(:tag, dim), bundle(Enum.map(tags, &vector(&1, dim))))]
      end

    bundle(parts)
  end

  @doc """
  Every symbol these facts can resolve to.

  `cleanup/2` needs the ids, the categories, and the tags, because an
  unbind may probe any of those roles.
  """
  @spec codebook([map()], pos_integer()) :: %{String.t() => Nx.Tensor.t()}
  def codebook(facts, dim \\ @default_dim) do
    facts
    |> Enum.flat_map(fn f -> [f.fact_id, f.category | f.tags] end)
    |> Enum.uniq()
    |> Map.new(&{&1, vector(&1, dim)})
  end
end
