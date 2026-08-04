# SPDX-License-Identifier: MIT
#
# LingBot-Map environment scan, as a RECTGTN HTN domain.
# RFD 0050 records why the calibration is a guard and not a step.
#
# The scale is the product. A twin that is 3 percent small is not a
# twin, thus a_write_stage requires /have/metric and a failed scan
# produces nothing.
#
# The orientation rule comes from decisions/agent/DECISIONS.md, dated
# 2026-07-26. A LingBot cloud is gravity aligned. It must never take
# the TripoSplat X-flip, and it must never load through the XYZRGB
# point stride, because that stride scatters a Gaussian PLY.
defmodule LingbotMapEnvironmentScan do
  use Taskweft.DSL

  @name "lingbot_map_environment_scan"

  @variables %{
    have: %{
      type: :bool,
      init: %{
        video: true,
        poses: false,
        surfaces: false,
        metric: false,
        stage: false
      }
    },
    handle: %{
      type: :ref,
      init: %{
        video: "/inputs/walk.mp4",
        poses: "",
        surfaces: "",
        stage: ""
      }
    },
    # Never anything but "none". See the module note above.
    orientation: %{
      type: :ref,
      init: %{mode: "none"}
    },
    loaded: %{
      type: :bool,
      init: %{
        phase_a: false,
        phase_b: false
      }
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
    # Phase A. Track the camera through the walk.
    a_track: %{
      params: [],
      body: [
        %{eval: %{type: "math/eq", a: %{pointer_get: "/loaded/phase_a"}, b: true}},
        %{eval: %{type: "math/eq", a: %{pointer_get: "/have/video"}, b: true}},
        %{pointer_set: "/have/poses", value: true},
        %{pointer_set: "/handle/poses", value: "/work/poses.json"}
      ]
    },
    # Phase B. It needs the poses, thus no plan may reverse the order.
    a_reconstruct: %{
      params: [],
      body: [
        %{eval: %{type: "math/eq", a: %{pointer_get: "/loaded/phase_b"}, b: true}},
        %{eval: %{type: "math/eq", a: %{pointer_get: "/have/poses"}, b: true}},
        %{eval: %{type: "math/eq", a: %{pointer_get: "/orientation/mode"}, b: "none"}},
        %{pointer_set: "/have/surfaces", value: true},
        %{pointer_set: "/handle/surfaces", value: "/work/surfaces.ply"}
      ]
    },
    # The door width is the check. A real door is a known width, thus
    # a wrong measurement means a wrong scale.
    a_calibrate: %{
      params: [],
      body: [
        %{eval: %{type: "math/eq", a: %{pointer_get: "/have/surfaces"}, b: true}},
        %{pointer_set: "/have/metric", value: true}
      ]
    },
    # Requires the metric gate. A failed scan produces no stage.
    a_write_stage: %{
      params: [],
      body: [
        %{eval: %{type: "math/eq", a: %{pointer_get: "/have/metric"}, b: true}},
        %{eval: %{type: "math/eq", a: %{pointer_get: "/orientation/mode"}, b: "none"}},
        %{pointer_set: "/have/stage", value: true},
        %{pointer_set: "/handle/stage", value: "/outputs/room.usdc"}
      ]
    }
  }

  @methods %{
    scan: %{
      params: [],
      alternatives: [
        %{
          name: :two_phase,
          subtasks: [
            ["a_load", "phase_a"],
            ["a_track"],
            ["a_unload", "phase_a"],
            ["a_load", "phase_b"],
            ["a_reconstruct"],
            ["a_unload", "phase_b"],
            ["a_calibrate"],
            ["a_write_stage"]
          ]
        }
      ]
    },
    have: %{
      params: [:artifact, :desired],
      alternatives: [
        %{
          name: :produce_stage,
          check: [%{eval: %{type: "math/eq", a: "{artifact}", b: "stage"}}],
          subtasks: [["scan"]]
        }
      ]
    }
  }

  @todo_list [["scan"]]
end
