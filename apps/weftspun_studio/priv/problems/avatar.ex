# SPDX-License-Identifier: MIT
#
# One image in, one published avatar out.
#
# A problem is an ordinary overlay. It goes last, thus its variables
# win and its todo_list replaces the base goal.
#
# The goal names the artifact, and not the steps. The composed domains
# supply the steps, thus a changed pipeline needs no change here.
defmodule WeftspunCMS.Problems.Avatar do
  use Taskweft.DSL

  @name "avatar_from_image"
  @source "content_lifecycle"

  @variables %{
    handle: %{
      type: :ref,
      init: %{source: "/inputs/portrait.png"}
    },
    # RFD 0053. VRM is the transmission format for an avatar.
    format: %{
      type: :ref,
      init: %{internal: "usd", transmission: "vrm"}
    }
  }

  @todo_list [%{goal: [%{pointer: "/have/published", eq: true}]}]
end
