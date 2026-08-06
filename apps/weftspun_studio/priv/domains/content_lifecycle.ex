# SPDX-License-Identifier: MIT
#
# The base content domain. Every pipeline composes over this one.
#
# It holds what a headless content system always does: take a source,
# run the stages, check the result, and publish it. It names no model
# and no stage, thus a new pipeline adds a document and changes nothing
# here.
#
# RFD 0054 records the composition. RFD 0023 records the shape.
defmodule WeftspunCMS.Domains.ContentLifecycle do
  use Taskweft.DSL

  @name "content_lifecycle"

  @variables %{
    # The artifact ladder. A stage domain sets `staged` when its own
    # work is done, and it never touches the rest.
    have: %{
      type: :bool,
      init: %{
        source: true,
        staged: false,
        validated: false,
        published: false
      }
    },
    # Where each artifact is. Opaque, and never parsed.
    handle: %{
      type: :ref,
      init: %{
        source: "/inputs/source",
        staged: "",
        published: ""
      }
    },
    # RFD 0053. USD inside, and a transmission format at the boundary.
    format: %{
      type: :ref,
      init: %{
        internal: "usd",
        transmission: "glb"
      }
    }
  }

  @actions %{
    # A composed stage domain provides the work. This action only
    # records that a stage ran, so the lifecycle can depend on it
    # without naming which stage.
    a_mark_staged: %{
      params: [],
      body: [
        %{eval: %{type: "math/eq", a: %{pointer_get: "/have/source"}, b: true}},
        %{pointer_set: "/have/staged", value: true}
      ]
    },
    # The gate. Nothing publishes before this passes.
    a_validate: %{
      params: [],
      body: [
        %{eval: %{type: "math/eq", a: %{pointer_get: "/have/staged"}, b: true}},
        %{pointer_set: "/have/validated", value: true}
      ]
    },
    # RFD 0053. The internal format stays USD, and the boundary writes
    # the transmission format.
    a_publish: %{
      params: [],
      body: [
        %{eval: %{type: "math/eq", a: %{pointer_get: "/have/validated"}, b: true}},
        %{eval: %{type: "math/eq", a: %{pointer_get: "/format/internal"}, b: "usd"}},
        %{pointer_set: "/have/published", value: true},
        %{pointer_set: "/handle/published", value: "/outputs/published"}
      ]
    }
  }

  @methods %{
    # A composed pipeline overrides this method. The default does the
    # least a lifecycle can do, thus the base domain plans alone and a
    # test needs no overlay to exercise it.
    run_stages: %{
      params: [],
      alternatives: [
        %{name: :no_stage, subtasks: [["a_mark_staged"]]}
      ]
    },
    deliver: %{
      params: [],
      alternatives: [
        %{name: :standard, subtasks: [["run_stages"], ["a_validate"], ["a_publish"]]}
      ]
    },
    # The goal method, named after the state variable it targets.
    have: %{
      params: [:artifact, :desired],
      alternatives: [
        %{
          name: :publish_it,
          check: [%{eval: %{type: "math/eq", a: "{artifact}", b: "published"}}],
          subtasks: [["deliver"]]
        }
      ]
    }
  }

  @todo_list [["deliver"]]
end
