# SPDX-License-Identifier: MIT
#
# The rig stage. It composes over content_lifecycle and stage_mesh.
#
# It overrides run_stages again, and its version calls the mesh
# actions. That works because compose merges the actions of every
# document before the planner sees them.
#
# RFD 0046 records the rig. The rig is an opinion about a mesh that
# already exists, thus it needs the mesh stage below it.
defmodule WeftspunCMS.Domains.StageRig do
  use Taskweft.DSL

  @name "stage_rig"

  @variables %{
    have: %{
      type: :bool,
      init: %{rig: false}
    },
    handle: %{
      type: :ref,
      init: %{rig: ""}
    },
    loaded: %{
      type: :bool,
      init: %{rig_model: false}
    }
  }

  @actions %{
    a_load_rig_model: %{
      params: [],
      body: [
        %{eval: %{type: "math/eq", a: %{pointer_get: "/loaded/rig_model"}, b: false}},
        %{pointer_set: "/loaded/rig_model", value: true}
      ]
    },
    a_unload_rig_model: %{
      params: [],
      body: [
        %{eval: %{type: "math/eq", a: %{pointer_get: "/loaded/rig_model"}, b: true}},
        %{pointer_set: "/loaded/rig_model", value: false}
      ]
    },
    # RFD 0046. UsdSkel carries the skeleton in its own layer, thus the
    # mesh layer below stays intact.
    a_rig: %{
      params: [],
      body: [
        %{eval: %{type: "math/eq", a: %{pointer_get: "/loaded/rig_model"}, b: true}},
        %{eval: %{type: "math/eq", a: %{pointer_get: "/have/mesh"}, b: true}},
        %{pointer_set: "/have/rig", value: true},
        %{pointer_set: "/handle/rig", value: "/work/rig.usda"}
      ]
    }
  }

  @methods %{
    # The third override of run_stages. It calls a_generate_mesh and
    # a_unwrap_uv from stage_mesh, which the merge already brought in.
    run_stages: %{
      params: [],
      alternatives: [
        %{
          name: :mesh_then_rig,
          subtasks: [
            ["a_load_mesh_model"],
            ["a_generate_mesh"],
            ["a_unload_mesh_model"],
            ["a_unwrap_uv"],
            ["a_load_rig_model"],
            ["a_rig"],
            ["a_unload_rig_model"],
            ["a_mark_staged"]
          ]
        }
      ]
    }
  }
end
