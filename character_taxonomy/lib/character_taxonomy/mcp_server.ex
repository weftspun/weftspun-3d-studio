# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule CharacterTaxonomy.MCPServer do
  @moduledoc """
  MCP server for RFD 0065's trait taxonomy.

  taskweft/taskweft runs its own MCP server, cited in RFD 0037, for
  `plan` and `validate` over any RECTGTN domain. This is a second,
  separate MCP service, scoped to one embedded domain,
  `character_concept_generator` (RFD 0064), and to the taxonomy
  resolve step RFD 0065 adds around it.

  ## Tools

  - `resolve_trait` — resolve or mint a capability id for one trait.
  - `observe_numeric` — widen a numeric role's observed range.
  - `taxonomy_snapshot` — the whole taxonomy, categories and numerics.
  - `plan` — run taskweft's planner over the embedded domain, or over
    a caller-supplied overlay problem on top of it.
  """

  use ExMCP.Server.Handler
  use ExMCP.Server.DSL, name: "character-taxonomy"

  alias CharacterTaxonomy.Taxonomy

  @domain_path Path.join(:code.priv_dir(:character_taxonomy), "domains/character_concept_generator.ex")

  tool "resolve_trait",
       "Resolve a trait value observed in one dataset row to a capability id, minting a new one on no near match." do
    param(:role, :string,
      required: true,
      description: "The trait role, such as hair_color, eye_color, pose, or clothing."
    )

    param(:text, :string,
      required: true,
      description: "The observed trait value, free text, from a vision inspection."
    )

    param(:threshold, :number,
      default: 0.85,
      description: "Minimum HRR similarity to count as the same capability."
    )

    handle(fn args, _state ->
      with {:ok, role} <- fetch_param(args, :role),
           {:ok, text} <- fetch_param(args, :text) do
        threshold = Map.get(args, :threshold, 0.85)
        {:ok, id, status} = Taxonomy.resolve_or_mint(CharacterTaxonomy.Taxonomy, role, text, threshold)
        {:ok, tool_text(Jason.encode!(%{capability_id: id, status: status}))}
      else
        {:error, reason} -> {:ok, tool_error(reason)}
      end
    end)
  end

  tool "observe_numeric",
       "Widen a numeric role's observed range with one dataset row's value." do
    param(:role, :string, required: true, description: "The numeric role, such as height_cm or age.")
    param(:value, :number, required: true, description: "The observed value.")

    handle(fn args, _state ->
      with {:ok, role} <- fetch_param(args, :role),
           {:ok, value} <- fetch_param(args, :value) do
        {lo, hi} = Taxonomy.observe_numeric(CharacterTaxonomy.Taxonomy, role, value)
        {:ok, tool_text(Jason.encode!(%{role: role, min: lo, max: hi}))}
      else
        {:error, reason} -> {:ok, tool_error(reason)}
      end
    end)
  end

  tool "taxonomy_snapshot",
       "The whole taxonomy resolved so far: categories minted per role, and numeric ranges observed per role." do
    handle(fn _args, _state ->
      {:ok, tool_text(Jason.encode!(Taxonomy.snapshot(CharacterTaxonomy.Taxonomy)))}
    end)
  end

  tool "plan",
       "Run taskweft's planner over the embedded character_concept_generator domain (RFD 0064), with an optional problem overlay." do
    param(:overlay_dsl, :string,
      description: "A problem module, in the same Elixir DSL, overriding @variables and @todo_list for one character."
    )

    handle(fn args, _state ->
      base = File.read!(@domain_path)

      documents =
        case Map.get(args, :overlay_dsl) do
          nil -> [base]
          "" -> [base]
          overlay -> [base, overlay]
        end

      with {:ok, domain_json} <- Taskweft.Compose.compose_strings(documents, format: "dsl"),
           {:ok, result} <- Taskweft.plan(domain_json) do
        {:ok, tool_text(result)}
      else
        {:error, reason} -> {:ok, tool_error(reason)}
      end
    end)
  end

  # ---------- HELPERS ----------

  defp fetch_param(args, key) do
    case Map.fetch(args, key) do
      {:ok, value} when not is_nil(value) -> {:ok, value}
      {:ok, nil} -> {:error, "missing required parameter: #{key}"}
      :error -> {:error, "missing required parameter: #{key}"}
    end
  end

  defp tool_text(text), do: %{content: [%{type: "text", text: text}]}

  defp tool_error(reason), do: tool_text(Jason.encode!(%{error: to_string(reason)}))
end
