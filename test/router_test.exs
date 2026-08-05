defmodule WeftspunStudio.RouterTest do
  @moduledoc """
  The HTTP surface for phase 1 of RFD 0019: the model catalog only.
  """

  use ExUnit.Case, async: true
  use Plug.Test
  import Mox

  alias WeftspunStudio.{CatalogSourceMock, Router}

  setup :verify_on_exit!

  defp call(conn), do: Router.call(conn, Router.init([]))
  defp body(conn), do: Jason.decode!(conn.resp_body)

  describe "with the real adapter" do
    test "GET /api/v1/models serves every client entry" do
      conn = call(conn(:get, "/api/v1/models"))

      assert conn.status == 200
      assert ["application/json" <> _] = get_resp_header(conn, "content-type")

      models = body(conn)["models"]
      assert length(models) == 28
      assert %{"value" => _, "label" => _, "feature" => _} = hd(models)
    end

    test "GET /api/v1/models?feature= filters" do
      conn = call(conn(:get, "/api/v1/models?feature=uv_unwrapping"))

      assert conn.status == 200
      assert [%{"value" => "xatlas_uv_unwrapping"}] = body(conn)["models"]
    end

    test "GET /api/v1/models/features lists the feature keys" do
      features = body(call(conn(:get, "/api/v1/models/features")))["features"]

      assert "image_to_textured_mesh" in features
      assert features == Enum.sort(features)
    end

    test "GET /api/v1/health reports ok" do
      assert %{"status" => "ok"} = body(call(conn(:get, "/api/v1/health")))
    end

    test "an unknown route is 404 JSON" do
      conn = call(conn(:get, "/api/v1/nope"))
      assert conn.status == 404
      assert %{"error" => "not found"} = body(conn)
    end
  end

  describe "with a mocked catalog source" do
    setup do
      Application.put_env(:weftspun_studio, :catalog_source, CatalogSourceMock)
      on_exit(fn -> Application.delete_env(:weftspun_studio, :catalog_source) end)
      :ok
    end

    test "the route serves whatever the port returns" do
      entry = %{value: "fake_model", label: "Fake", feature: "text_to_3d"}
      expect(CatalogSourceMock, :list_models, fn _state -> [entry] end)

      assert %{"models" => [%{"value" => "fake_model"}]} =
               body(call(conn(:get, "/api/v1/models")))
    end

    test "the feature query reaches the port" do
      expect(CatalogSourceMock, :list_for_feature, fn _state, "auto_rig" -> [] end)

      assert %{"models" => []} = body(call(conn(:get, "/api/v1/models?feature=auto_rig")))
    end
  end
end
