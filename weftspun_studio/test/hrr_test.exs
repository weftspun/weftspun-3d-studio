defmodule WeftspunStudio.HrrTest do
  @moduledoc """
  Holographic Reduced Representations, after the hermes-agent store.

  The algebra must hold: binding is invertible, unrelated symbols are
  near orthogonal, and a bundle stays similar to its parts.
  """

  use ExUnit.Case, async: true

  alias WeftspunStudio.Hrr

  @dim 1024

  test "a token always maps to the same vector" do
    assert Nx.to_flat_list(Hrr.vector("trellis2", @dim)) ==
             Nx.to_flat_list(Hrr.vector("trellis2", @dim))
  end

  test "vectors are unit length" do
    norm = Hrr.vector("xatlas", @dim) |> Hrr.norm() |> Nx.to_number()
    assert_in_delta norm, 1.0, 1.0e-4
  end

  test "unrelated symbols are near orthogonal" do
    a = Hrr.vector("lama", @dim)
    b = Hrr.vector("marigold", @dim)

    assert abs(Nx.to_number(Hrr.similarity(a, b))) < 0.2
  end

  test "unbinding recovers the bound filler" do
    role = Hrr.vector("category", @dim)
    filler = Hrr.vector("image_to_textured_mesh", @dim)

    recovered = role |> Hrr.bind(filler) |> Hrr.unbind(role)

    assert Nx.to_number(Hrr.similarity(recovered, filler)) > 0.9
  end

  test "binding commutes" do
    a = Hrr.vector("a", @dim)
    b = Hrr.vector("b", @dim)

    assert Nx.to_number(Hrr.similarity(Hrr.bind(a, b), Hrr.bind(b, a))) > 0.999
  end

  test "a bundle stays similar to each part" do
    parts = for t <- ~w(one two three), do: Hrr.vector(t, @dim)
    bundle = Hrr.bundle(parts)

    for part <- parts do
      assert Nx.to_number(Hrr.similarity(bundle, part)) > 0.3
    end
  end

  test "cleanup picks the nearest codebook entry" do
    codebook = for t <- ~w(alpha beta gamma), into: %{}, do: {t, Hrr.vector(t, @dim)}
    noisy = Hrr.vector("beta", @dim) |> Nx.add(Nx.multiply(Hrr.vector("noise", @dim), 0.3))

    assert {"beta", score} = Hrr.cleanup(noisy, codebook)
    assert score > 0.5
  end

  describe "fact encoding" do
    setup do
      fact = %{
        fact_id: "trellis2_image_to_textured_mesh",
        content: "TRELLIS.2 Image to Textured Mesh",
        category: "image_to_textured_mesh",
        tags: ["deep_learning", "dgx_api", "active"],
        trust_score: 0.9,
        updated_at: DateTime.from_unix!(0)
      }

      %{fact: fact, vector: Hrr.encode_fact(fact, @dim)}
    end

    test "the encoded vector has the configured width", %{vector: v} do
      assert Nx.shape(v) == {@dim}
    end

    test "the category role unbinds back to the category", %{fact: fact, vector: v} do
      codebook = Hrr.codebook([fact], @dim)
      probe = Hrr.unbind(v, Hrr.role(:category, @dim))

      assert {"image_to_textured_mesh", _} = Hrr.cleanup(probe, codebook)
    end

    test "the id role unbinds back to the id", %{fact: fact, vector: v} do
      codebook = Hrr.codebook([fact], @dim)
      probe = Hrr.unbind(v, Hrr.role(:id, @dim))

      assert {"trellis2_image_to_textured_mesh", _} = Hrr.cleanup(probe, codebook)
    end

    test "two facts sharing a category are more alike than two that do not" do
      same = Hrr.encode_fact(%{fact_id: "b", content: "B", category: "image_to_textured_mesh",
                               tags: ["deep_learning"], trust_score: 0.9,
                               updated_at: DateTime.from_unix!(0)}, @dim)

      other = Hrr.encode_fact(%{fact_id: "c", content: "C", category: "auto_rig",
                                tags: ["geometric"], trust_score: 0.9,
                                updated_at: DateTime.from_unix!(0)}, @dim)

      base = Hrr.encode_fact(%{fact_id: "a", content: "A", category: "image_to_textured_mesh",
                               tags: ["deep_learning"], trust_score: 0.9,
                               updated_at: DateTime.from_unix!(0)}, @dim)

      assert Nx.to_number(Hrr.similarity(base, same)) >
               Nx.to_number(Hrr.similarity(base, other))
    end
  end
end
