# SPDX-License-Identifier: MIT
#
# One anime image in, one layered PSD out.
#
# The todo_list names the artifact, and not the steps. The planner
# takes the steps from domain.ex, thus a changed pipeline needs no
# change here. RFD 0044 records that split.
defmodule SeethroughOneImage do
  use Taskweft.DSL

  @name "seethrough_one_image"
  @source "seethrough_layer_decomposition"

  # Only the keys this problem changes. The domain supplies the rest.
  @variables %{
    handle: %{
      type: :ref,
      init: %{
        image: "/inputs/character.png",
        psd: ""
      }
    }
  }

  @todo_list [%{goal: [%{pointer: "/have/psd", eq: true}]}]
end
