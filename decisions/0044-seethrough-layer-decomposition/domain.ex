# SPDX-License-Identifier: MIT
#
# See-Through layer decomposition, as a RECTGTN HTN domain.
# RFD 0044 records why this pipeline is a domain and not a script.
#
# Nine networks. RFD 0030 lists them with their memory. The guards
# below state the order, thus a reader sees what waits on what.
#
# a_load and a_unload are real actions on purpose. The peak memory is
# then a planning result, and not an accident.
defmodule SeethroughLayerDecomposition do
  use Taskweft.DSL

  @name "seethrough_layer_decomposition"

  @variables %{
    # Which artifact exists. The whole ordering rests on this.
    have: %{
      type: :bool,
      init: %{
        image: true,
        prompt_embeds: false,
        inpainted: false,
        latents: false,
        rgb_layers: false,
        alpha_layers: false,
        depth_latents: false,
        depth: false,
        psd: false
      }
    },
    # Where each artifact is. An opaque reference, never parsed.
    handle: %{
      type: :ref,
      init: %{
        image: "/inputs/image.png",
        prompt_embeds: "",
        inpainted: "",
        latents: "",
        rgb_layers: "",
        alpha_layers: "",
        depth_latents: "",
        depth: "",
        psd: ""
      }
    },
    # Which component is resident. RFD 0027 caps the total.
    loaded: %{
      type: :bool,
      init: %{
        lama: false,
        layerdiff_te1: false,
        layerdiff_te2: false,
        layerdiff_unet: false,
        layerdiff_vae: false,
        trans_vae: false,
        marigold_te: false,
        marigold_unet: false,
        marigold_vae: false
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
    # Both CLIP encoders run. SDXL needs the pair.
    a_encode_prompt: %{
      params: [],
      body: [
        %{eval: %{type: "math/eq", a: %{pointer_get: "/loaded/layerdiff_te1"}, b: true}},
        %{eval: %{type: "math/eq", a: %{pointer_get: "/loaded/layerdiff_te2"}, b: true}},
        %{pointer_set: "/have/prompt_embeds", value: true},
        %{pointer_set: "/handle/prompt_embeds", value: "/work/prompt_embeds.safetensors"}
      ]
    },
    # LaMa fills what the front layer hides. The layer model
    # conditions on the filled image, thus this runs first.
    a_inpaint: %{
      params: [],
      body: [
        %{eval: %{type: "math/eq", a: %{pointer_get: "/loaded/lama"}, b: true}},
        %{eval: %{type: "math/eq", a: %{pointer_get: "/have/image"}, b: true}},
        %{pointer_set: "/have/inpainted", value: true},
        %{pointer_set: "/handle/inpainted", value: "/work/inpainted.png"}
      ]
    },
    # The largest component at 5.13 GB in bf16.
    a_diffuse_layers: %{
      params: [],
      body: [
        %{eval: %{type: "math/eq", a: %{pointer_get: "/loaded/layerdiff_unet"}, b: true}},
        %{eval: %{type: "math/eq", a: %{pointer_get: "/have/prompt_embeds"}, b: true}},
        %{eval: %{type: "math/eq", a: %{pointer_get: "/have/inpainted"}, b: true}},
        %{pointer_set: "/have/latents", value: true},
        %{pointer_set: "/handle/latents", value: "/work/latents.safetensors"}
      ]
    },
    a_decode_rgb: %{
      params: [],
      body: [
        %{eval: %{type: "math/eq", a: %{pointer_get: "/loaded/layerdiff_vae"}, b: true}},
        %{eval: %{type: "math/eq", a: %{pointer_get: "/have/latents"}, b: true}},
        %{pointer_set: "/have/rgb_layers", value: true},
        %{pointer_set: "/handle/rgb_layers", value: "/work/rgb"}
      ]
    },
    # Reads the same latents as the RGB decode. That is the fact a
    # reader of the old script always missed.
    a_decode_alpha: %{
      params: [],
      body: [
        %{eval: %{type: "math/eq", a: %{pointer_get: "/loaded/trans_vae"}, b: true}},
        %{eval: %{type: "math/eq", a: %{pointer_get: "/have/latents"}, b: true}},
        %{pointer_set: "/have/alpha_layers", value: true},
        %{pointer_set: "/handle/alpha_layers", value: "/work/alpha"}
      ]
    },
    a_depth_encode: %{
      params: [],
      body: [
        %{eval: %{type: "math/eq", a: %{pointer_get: "/loaded/marigold_te"}, b: true}},
        %{eval: %{type: "math/eq", a: %{pointer_get: "/loaded/marigold_unet"}, b: true}},
        %{pointer_set: "/have/depth_latents", value: true},
        %{pointer_set: "/handle/depth_latents", value: "/work/depth_latents.safetensors"}
      ]
    },
    a_depth_decode: %{
      params: [],
      body: [
        %{eval: %{type: "math/eq", a: %{pointer_get: "/loaded/marigold_vae"}, b: true}},
        %{eval: %{type: "math/eq", a: %{pointer_get: "/have/depth_latents"}, b: true}},
        %{pointer_set: "/have/depth", value: true},
        %{pointer_set: "/handle/depth", value: "/work/depth.png"}
      ]
    },
    a_write_psd: %{
      params: [],
      body: [
        %{eval: %{type: "math/eq", a: %{pointer_get: "/have/rgb_layers"}, b: true}},
        %{eval: %{type: "math/eq", a: %{pointer_get: "/have/alpha_layers"}, b: true}},
        %{eval: %{type: "math/eq", a: %{pointer_get: "/have/depth"}, b: true}},
        %{pointer_set: "/have/psd", value: true},
        %{pointer_set: "/handle/psd", value: "/outputs/layers.psd"}
      ]
    }
  }

  @methods %{
    # Fill the hidden area, and encode the prompt.
    prepare: %{
      params: [],
      alternatives: [
        %{
          name: :inpaint_then_encode,
          subtasks: [
            ["a_load", "lama"],
            ["a_inpaint"],
            ["a_unload", "lama"],
            ["a_load", "layerdiff_te1"],
            ["a_load", "layerdiff_te2"],
            ["a_encode_prompt"],
            ["a_unload", "layerdiff_te1"],
            ["a_unload", "layerdiff_te2"]
          ]
        }
      ]
    },
    # Generate the latents once, and decode them twice.
    make_layers: %{
      params: [],
      alternatives: [
        %{
          name: :diffuse_then_decode,
          subtasks: [
            ["a_load", "layerdiff_unet"],
            ["a_diffuse_layers"],
            ["a_unload", "layerdiff_unet"],
            ["a_load", "layerdiff_vae"],
            ["a_decode_rgb"],
            ["a_unload", "layerdiff_vae"],
            ["a_load", "trans_vae"],
            ["a_decode_alpha"],
            ["a_unload", "trans_vae"]
          ]
        }
      ]
    },
    # Marigold runs on the original image, thus it does not wait for
    # the layers. The planner may order this before make_layers.
    make_depth: %{
      params: [],
      alternatives: [
        %{
          name: :encode_then_decode,
          subtasks: [
            ["a_load", "marigold_te"],
            ["a_load", "marigold_unet"],
            ["a_depth_encode"],
            ["a_unload", "marigold_te"],
            ["a_unload", "marigold_unet"],
            ["a_load", "marigold_vae"],
            ["a_depth_decode"],
            ["a_unload", "marigold_vae"]
          ]
        }
      ]
    },
    decompose: %{
      params: [],
      alternatives: [
        %{
          name: :standard,
          subtasks: [["prepare"], ["make_layers"], ["make_depth"], ["a_write_psd"]]
        }
      ]
    },
    # A goal method is an ordinary method named after the state
    # variable it targets. A problem may then ask for the artifact,
    # and not for the steps.
    have: %{
      params: [:artifact, :desired],
      alternatives: [
        %{
          name: :produce_psd,
          check: [%{eval: %{type: "math/eq", a: "{artifact}", b: "psd"}}],
          subtasks: [["decompose"]]
        }
      ]
    }
  }

  @todo_list [["decompose"]]
end
