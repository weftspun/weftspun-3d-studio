# SPDX-License-Identifier: MIT
#
# One walk video in, one 1:1 metric room twin out.
#
# orientation.mode stays "none". A LingBot cloud is gravity aligned,
# and RFD 0050 records why any other value is wrong.
defmodule LingbotScanOneRoom do
  use Taskweft.DSL

  @name "lingbot_scan_one_room"
  @source "lingbot_map_environment_scan"

  @variables %{
    handle: %{
      type: :ref,
      init: %{
        video: "/inputs/walk.mp4",
        stage: ""
      }
    },
    orientation: %{
      type: :ref,
      init: %{mode: "none"}
    }
  }

  @todo_list [%{goal: [%{pointer: "/have/stage", eq: true}]}]
end
