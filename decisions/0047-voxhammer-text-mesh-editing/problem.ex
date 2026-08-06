# SPDX-License-Identifier: MIT
#
# Edit one region of one mesh from a sentence.
#
# The todo_list asks for the layer, and not for the steps. RFD 0047
# records why the splice guard makes this worth planning.
defmodule VoxhammerTextEditOne do
  use Taskweft.DSL

  @name "voxhammer_text_edit_one"
  @source "voxhammer_mesh_editing"

  @variables %{
    handle: %{
      type: :ref,
      init: %{
        mesh: "/inputs/source.usdc",
        layer: ""
      }
    },
    mode: %{
      type: :ref,
      init: %{conditioning: "text"}
    }
  }

  @todo_list [%{goal: [%{pointer: "/have/layer", eq: true}]}]
end
