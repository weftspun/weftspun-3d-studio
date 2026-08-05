# SPDX-License-Identifier: MIT
#
# Character concept authoring, as a RECTGTN HTN domain.
# RFD 0064 records why this pipeline is a domain and not a script.
# RFD 0065 records the schema this file follows.
#
# `trait` and `numeric` hold one value per character, per RFD 0065's
# rule 1. Each value comes from CharacterTaxonomy.Taxonomy, which
# resolves or creates a capability id before a problem.ex ever calls
# a_set_trait. This domain holds no fixed capability list, so it
# stays correct as the taxonomy grows from the training data.
defmodule CharacterConceptGenerator do
  use Taskweft.DSL

  @name "character_concept_generator"

  @variables %{
    trait: %{
      type: :ref,
      init: %{hair_color: "", eye_color: "", pose: "", clothing: ""}
    },
    numeric: %{
      type: :int,
      init: %{height_cm: 0, age: 0}
    },
    have: %{
      type: :bool,
      init: %{character: false}
    }
  }

  @actions %{
    # capability_id comes from
    # CharacterTaxonomy.Taxonomy.resolve_or_create/4. The guard stops
    # a second call from overwriting an already-set role, which keeps
    # one value per character per role, the functional dependency
    # RFD 0065 rests on.
    a_set_trait: %{
      params: [:role, :capability_id],
      body: [
        %{eval: %{type: "math/eq", a: %{pointer_get: "/trait/{role}"}, b: ""}},
        %{pointer_set: "/trait/{role}", value: "{capability_id}"}
      ]
    },
    a_set_numeric: %{
      params: [:role, :value],
      body: [
        %{pointer_set: "/numeric/{role}", value: "{value}"}
      ]
    },
    a_finish_character: %{
      params: [],
      body: [
        %{pointer_set: "/have/character", value: true}
      ]
    }
  }

  @methods %{
    have: %{
      params: [:artifact, :desired],
      alternatives: [
        %{
          name: :produce_character,
          check: [%{eval: %{type: "math/eq", a: "{artifact}", b: "character"}}],
          subtasks: [["a_finish_character"]]
        }
      ]
    }
  }

  # The shared domain's own default plan. One problem.ex per dataset
  # row overrides this with its own a_set_trait/a_set_numeric calls,
  # each carrying that row's resolved capability ids, ahead of the
  # same a_finish_character step.
  @todo_list [["a_finish_character"]]
end
