# SPDX-License-Identifier: MIT
#
# GENERATED. Do not edit by hand.
#
# The taskweft `plan` tool solved domain.ex, and this file holds the
# result. RFD 0037 records why: a cold start then needs no planner and
# no network.
#
# Regenerate when domain.ex changes. A hand-edited plan can hold a
# step order the guards forbid, which is the failure the domain exists
# to stop.
#
#   mcp__taskweft__plan(domain_dsl: File.read!("domain.ex"), format: "dsl")
defmodule SeethroughLayerDecompositionPlan do
  @source "seethrough_layer_decomposition"
  @solved_by "taskweft v0.5.3"
  @temporally_consistent true

  # 26 steps. The load and unload pairs come from the domain, thus the
  # peak memory is a planning result. Only one component is resident at
  # a time here, except for the two CLIP encoders and the two Marigold
  # halves, which their actions need together.
  @plan [
    ["a_load", "lama"],
    ["a_inpaint"],
    ["a_unload", "lama"],
    ["a_load", "layerdiff_te1"],
    ["a_load", "layerdiff_te2"],
    ["a_encode_prompt"],
    ["a_unload", "layerdiff_te1"],
    ["a_unload", "layerdiff_te2"],
    ["a_load", "layerdiff_unet"],
    ["a_diffuse_layers"],
    ["a_unload", "layerdiff_unet"],
    ["a_load", "layerdiff_vae"],
    ["a_decode_rgb"],
    ["a_unload", "layerdiff_vae"],
    ["a_load", "trans_vae"],
    ["a_decode_alpha"],
    ["a_unload", "trans_vae"],
    ["a_load", "marigold_te"],
    ["a_load", "marigold_unet"],
    ["a_depth_encode"],
    ["a_unload", "marigold_te"],
    ["a_unload", "marigold_unet"],
    ["a_load", "marigold_vae"],
    ["a_depth_decode"],
    ["a_unload", "marigold_vae"],
    ["a_write_psd"]
  ]

  def plan, do: @plan
  def source, do: @source
end
