# SPDX-License-Identifier: MIT
#
# GENERATED. Do not edit by hand. Regenerate when domain.ex changes.
#
#   mcp__taskweft__plan(domain_dsl: File.read!("domain.ex"), format: "dsl")
defmodule VoxhammerTextMeshEditingPlan do
  @source "voxhammer_mesh_editing"
  @solved_by "taskweft v0.5.3"
  @temporally_consistent true

  # 7 steps. apply_edit took its :text alternative, because
  # mode.conditioning is "text". RFD 0048 solves the same domain with
  # "image" and gets a_edit_image in this slot.
  #
  # a_splice comes before a_decode, which is the guard RFD 0047 exists
  # for. The planner cannot order them the other way.
  @plan [
    ["a_mark_region"],
    ["a_voxelize"],
    ["a_invert"],
    ["a_edit_text"],
    ["a_splice"],
    ["a_decode"],
    ["a_write_layer"]
  ]

  def plan, do: @plan
  def source, do: @source
end
