# SPDX-License-Identifier: MIT
#
# One image in, one explorable world out, with no props.
#
# This is the common case. The plan it produces never mentions
# TRELLIS.2, because build_props takes its :none alternative. RFD 0049
# records why that matters.
defmodule WeftspunWorldEnvironmentOnly do
  use Taskweft.DSL

  @name "weftspun_world_environment_only"
  @source "weftspun_image_to_world"

  @variables %{
    handle: %{
      type: :ref,
      init: %{
        image: "/inputs/scene.png",
        stage: ""
      }
    },
    want: %{
      type: :int,
      init: %{prop_count: 0}
    }
  }

  @todo_list [%{goal: [%{pointer: "/have/stage", eq: true}]}]
end
