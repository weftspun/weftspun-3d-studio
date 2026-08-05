# SPDX-License-Identifier: MIT
#
# GENERATED. Do not edit by hand. Regenerate when domain.ex changes.
#
#   mcp__taskweft__plan(domain_dsl: File.read!("domain.ex"), format: "dsl")
defmodule LingbotMapEnvironmentScanPlan do
  @source "lingbot_map_environment_scan"
  @solved_by "taskweft v0.5.3"
  @temporally_consistent true

  # 8 steps. Phase A tracks, and Phase B reconstructs from its poses.
  # The two never stay resident together.
  #
  # a_calibrate comes before a_write_stage, which is the metric gate.
  # A scan that fails the door check therefore writes no stage at all.
  #
  # RFD 0050 stays in prediscussion. This plan is the step order, and
  # not a statement that the model is ready to package.
  @plan [
    ["a_load", "phase_a"],
    ["a_track"],
    ["a_unload", "phase_a"],
    ["a_load", "phase_b"],
    ["a_reconstruct"],
    ["a_unload", "phase_b"],
    ["a_calibrate"],
    ["a_write_stage"]
  ]

  def plan, do: @plan
  def source, do: @source
end
