# SPDX-License-Identifier: MIT
#
# The mesh stage. It composes over content_lifecycle.
#
# It adds its own actions, and it overrides run_stages to use them.
# The lifecycle below keeps its validate and publish steps, and it
# never learns that a mesh model exists.
#
# This is the point of composition. A second pipeline that also makes a
# mesh reuses this document, and no copy drifts.
defmodule WeftspunCMS.Domains.StageMesh do
  use Taskweft.DSL

  @name "stage_mesh"

  @variables %{
    have: %{
      type: :bool,
      init: %{
        mesh: false,
        uv: false
      }
    },
    handle: %{
      type: :ref,
      init: %{mesh: ""}
    },
    # RFD 0027. The planner unloads between stages, thus the peak is
    # one model and not the sum.
    loaded: %{
      type: :bool,
      init: %{mesh_model: false}
    }
  }

  @actions %{
    a_load_mesh_model: %{
      params: [],
      body: [
        %{eval: %{type: "math/eq", a: %{pointer_get: "/loaded/mesh_model"}, b: false}},
        %{pointer_set: "/loaded/mesh_model", value: true}
      ]
    },
    a_unload_mesh_model: %{
      params: [],
      body: [
        %{eval: %{type: "math/eq", a: %{pointer_get: "/loaded/mesh_model"}, b: true}},
        %{pointer_set: "/loaded/mesh_model", value: false}
      ]
    },
    # RFD 0040. Pixal3D is the image to 3D path in daily use.
    a_generate_mesh: %{
      params: [],
      body: [
        %{eval: %{type: "math/eq", a: %{pointer_get: "/loaded/mesh_model"}, b: true}},
        %{eval: %{type: "math/eq", a: %{pointer_get: "/have/source"}, b: true}},
        %{pointer_set: "/have/mesh", value: true},
        %{pointer_set: "/handle/mesh", value: "/work/mesh.usdc"}
      ]
    },
    # RFD 0039. The painting stage needs a UV set, and it does not
    # unwrap. xatlas holds no weights, thus this step loads nothing.
    a_unwrap_uv: %{
      params: [],
      body: [
        %{eval: %{type: "math/eq", a: %{pointer_get: "/have/mesh"}, b: true}},
        %{pointer_set: "/have/uv", value: true}
      ]
    }
  }

  @methods %{
    # Overrides the base. Compose puts this document after the
    # lifecycle, thus this alternative replaces :no_stage.
    run_stages: %{
      params: [],
      alternatives: [
        %{
          name: :mesh_then_uv,
          subtasks: [
            ["a_load_mesh_model"],
            ["a_generate_mesh"],
            ["a_unload_mesh_model"],
            ["a_unwrap_uv"],
            ["a_mark_staged"]
          ]
        }
      ]
    }
  }
end
