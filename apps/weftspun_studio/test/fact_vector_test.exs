# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule WeftspunStudio.FactVectorTest do
  use ExUnit.Case, async: true

  alias WeftspunStudio.FactVector

  @dim 1024

  defp fact(overrides \\ %{}) do
    Map.merge(
      %{
        fact_id: "trellis_text_to_textured_mesh",
        category: "text_to_textured_mesh",
        tags: ["deep_learning", "dgx_api", "active"]
      },
      overrides
    )
  end

  describe "encode/2" do
    test "gives a phase vector of the requested width" do
      vector = FactVector.encode(fact(), @dim)

      assert Nx.shape(vector) == {@dim}
      assert Nx.type(vector) == {:f, 64}
    end

    test "every phase stays in the zero to two pi range" do
      vector = FactVector.encode(fact(), @dim)

      assert Nx.to_number(Nx.all(Nx.greater_equal(vector, 0.0))) == 1
      assert Nx.to_number(Nx.all(Nx.less(vector, 2.0 * :math.pi()))) == 1
    end

    test "the same fact always gives the same vector" do
      assert FactVector.encode(fact(), @dim) |> Nx.to_binary() ==
               FactVector.encode(fact(), @dim) |> Nx.to_binary()
    end

    test "a different fact gives a different vector" do
      other = fact(%{fact_id: "hunyuan3dv21_image_to_raw_mesh"})

      assert HRR.similarity(FactVector.encode(fact(), @dim), FactVector.encode(other, @dim)) < 0.9
    end

    test "a fact with no tags still encodes" do
      vector = FactVector.encode(fact(%{tags: []}), @dim)

      assert Nx.shape(vector) == {@dim}
    end
  end

  describe "probe/3" do
    test "recovers the category bound into a fact" do
      vector = FactVector.encode(fact(), @dim)
      book = FactVector.codebook([fact()], @dim)

      assert {"text_to_textured_mesh", score} = FactVector.probe(vector, :category, book)
      assert score > 0.3
    end

    test "recovers the id bound into a fact" do
      vector = FactVector.encode(fact(), @dim)
      book = FactVector.codebook([fact()], @dim)

      assert {"trellis_text_to_textured_mesh", score} = FactVector.probe(vector, :id, book)
      assert score > 0.3
    end
  end

  describe "codebook/2" do
    test "holds every id, category, and tag" do
      book = FactVector.codebook([fact()], @dim)

      assert Map.has_key?(book, "trellis_text_to_textured_mesh")
      assert Map.has_key?(book, "text_to_textured_mesh")
      assert Map.has_key?(book, "deep_learning")
    end
  end

  describe "query/2" do
    test "a query term ranks its own fact above a stranger" do
      probe = FactVector.query("text_to_textured_mesh", @dim)

      match = HRR.similarity(probe, FactVector.encode(fact(), @dim))

      stranger =
        HRR.similarity(
          probe,
          FactVector.encode(
            fact(%{
              fact_id: "marigold_unet",
              category: "depth",
              tags: ["deep_learning", "local"]
            }),
            @dim
          )
        )

      assert match > stranger
    end

    test "an empty query gives a vector rather than a crash" do
      assert Nx.shape(FactVector.query("", @dim)) == {@dim}
    end

    test "punctuation and case do not change the query" do
      assert Nx.to_binary(FactVector.query("Text_To_Textured_Mesh", @dim)) ==
               Nx.to_binary(FactVector.query("text_to_textured_mesh", @dim))
    end
  end

  describe "serialisation" do
    test "a vector round-trips through binary" do
      vector = FactVector.encode(fact(), @dim)

      assert vector |> HRR.to_binary() |> HRR.from_binary() |> Nx.to_binary() ==
               Nx.to_binary(vector)
    end

    test "the stored width matches the dimension" do
      assert byte_size(HRR.to_binary(FactVector.encode(fact(), @dim))) == @dim * 8
    end
  end
end
