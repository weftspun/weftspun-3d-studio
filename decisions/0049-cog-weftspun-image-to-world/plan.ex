# SPDX-License-Identifier: MIT
#
# GENERATED. Do not edit by hand. Regenerate when domain.ex changes.
#
#   mcp__taskweft__plan(domain_dsl: File.read!("domain.ex"), format: "dsl")
defmodule WeftspunImageToWorldPlan do
  @source "weftspun_image_to_world"
  @solved_by "taskweft v0.5.3"
  @temporally_consistent true

  # 4 steps, and TRELLIS.2 is absent from every one.
  #
  # want.prop_count is 0, thus build_props took its :none alternative
  # and contributed no step. That is the evidence for the RFD 0049
  # claim: the environment-only job never loads the mesh model. A
  # script would load it and then skip it.
  #
  # A problem that sets prop_count above 0 plans the :some
  # alternative, and three more steps appear.
  @plan [
    ["a_load", "triposplat"],
    ["a_make_splat"],
    ["a_unload", "triposplat"],
    ["a_compose_stage"]
  ]

  def plan, do: @plan
  def source, do: @source
end
