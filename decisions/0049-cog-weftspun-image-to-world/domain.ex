# SPDX-License-Identifier: MIT
#
# Image to explorable world, as a RECTGTN HTN domain.
# RFD 0049 records why this is a domain and not a script.
#
# Two models with no weights of their own here. TripoSplat comes from
# RFD 0052, and TRELLIS.2 comes from RFD 0038.
#
# The point of planning this: prop_count of 0 is the common case, and
# the plan for that job never mentions TRELLIS.2. A script would load
# the mesh model and then skip it.
defmodule WeftspunImageToWorld do
  use Taskweft.DSL

  @name "weftspun_image_to_world"

  @variables %{
    have: %{
      type: :bool,
      init: %{
        image: true,
        splat: false,
        props: false,
        stage: false
      }
    },
    handle: %{
      type: :ref,
      init: %{
        image: "/inputs/scene.png",
        splat: "",
        props: "",
        stage: ""
      }
    },
    loaded: %{
      type: :bool,
      init: %{
        triposplat: false,
        trellis2: false
      }
    },
    # 0 means environment only. The alternatives below branch on it.
    want: %{
      type: :int,
      init: %{prop_count: 0}
    }
  }

  @actions %{
    a_load: %{
      params: [:component],
      body: [
        %{eval: %{type: "math/eq", a: %{pointer_get: "/loaded/{component}"}, b: false}},
        %{pointer_set: "/loaded/{component}", value: true}
      ]
    },
    a_unload: %{
      params: [:component],
      body: [
        %{eval: %{type: "math/eq", a: %{pointer_get: "/loaded/{component}"}, b: true}},
        %{pointer_set: "/loaded/{component}", value: false}
      ]
    },
    # The environment. One image gives one radiance field.
    a_make_splat: %{
      params: [],
      body: [
        %{eval: %{type: "math/eq", a: %{pointer_get: "/loaded/triposplat"}, b: true}},
        %{eval: %{type: "math/eq", a: %{pointer_get: "/have/image"}, b: true}},
        %{pointer_set: "/have/splat", value: true},
        %{pointer_set: "/handle/splat", value: "/work/environment.ply"}
      ]
    },
    # The props. Only runs when prop_count is above 0.
    a_make_props: %{
      params: [],
      body: [
        %{eval: %{type: "math/eq", a: %{pointer_get: "/loaded/trellis2"}, b: true}},
        %{pointer_set: "/have/props", value: true},
        %{pointer_set: "/handle/props", value: "/work/props"}
      ]
    },
    # RFD 0053. The splat is one layer, and each prop is a reference
    # under its own prim.
    a_compose_stage: %{
      params: [],
      body: [
        %{eval: %{type: "math/eq", a: %{pointer_get: "/have/splat"}, b: true}},
        %{pointer_set: "/have/stage", value: true},
        %{pointer_set: "/handle/stage", value: "/outputs/world.usdc"}
      ]
    }
  }

  @methods %{
    build_environment: %{
      params: [],
      alternatives: [
        %{
          name: :splat_only,
          subtasks: [
            ["a_load", "triposplat"],
            ["a_make_splat"],
            ["a_unload", "triposplat"]
          ]
        }
      ]
    },
    # Two alternatives. The planner takes the second one only when
    # the caller asked for props, thus the common job stays cheap.
    build_props: %{
      params: [],
      alternatives: [
        %{
          name: :none,
          check: [%{eval: %{type: "math/eq", a: %{pointer_get: "/want/prop_count"}, b: 0}}],
          subtasks: []
        },
        %{
          name: :some,
          subtasks: [
            ["a_load", "trellis2"],
            ["a_make_props"],
            ["a_unload", "trellis2"]
          ]
        }
      ]
    },
    build_world: %{
      params: [],
      alternatives: [
        %{
          name: :standard,
          subtasks: [["build_environment"], ["build_props"], ["a_compose_stage"]]
        }
      ]
    },
    have: %{
      params: [:artifact, :desired],
      alternatives: [
        %{
          name: :produce_stage,
          check: [%{eval: %{type: "math/eq", a: "{artifact}", b: "stage"}}],
          subtasks: [["build_world"]]
        }
      ]
    }
  }

  @todo_list [["build_world"]]
end
