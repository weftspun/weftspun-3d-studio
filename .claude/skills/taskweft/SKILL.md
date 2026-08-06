---
name: taskweft
description: Write, solve, and maintain RECTGTN HTN planning domains with the taskweft MCP server. Use when working on decisions/*/domain.ex, problem.ex, or plan.ex, when a pipeline runs several models in order, or when the user mentions taskweft, HTN, RECTGTN, a planning domain, or replanning.
---

# taskweft

An HTN planner served over MCP. It turns a domain and a problem into
an ordered plan.

This repository models each composite model as a domain. RFD 0037
records why. A composite runs several networks, and a Python script
hides the order, the guards, and the failure point. A script also
cannot replan.

## The two tools

| Tool | Does |
| ---- | ---- |
| `mcp__taskweft__plan` | Returns the plan and its temporal check. |
| `mcp__taskweft__validate` | Checks a domain, and returns no plan. |

Both take `domain_dsl` as a **string**, not a path. Read the file, and
pass its contents.

```
mcp__taskweft__plan(domain_dsl: <contents of domain.ex>, format: "dsl")
```

`format` takes `dsl` by default. Use `json` only for JSON-LD, which
this repository no longer writes.

## If the tools are absent

MCP tools register at session start. When the server is added or
reloaded mid-session, restart the session or run `/reload-plugins`.
Then confirm with `ToolSearch("select:mcp__taskweft__plan")`.

`claude mcp list` reporting Connected does not mean the tools are
callable in the current session.

## The domain shape

A domain is a module with `use Taskweft.DSL` and module attributes.

| Attribute | Holds |
| --------- | ----- |
| `@name` | The domain name. |
| `@variables` | `name => %{type:, init:}`. The state. |
| `@actions` | Primitives. `params`, `bind`, and `body`. |
| `@methods` | Compound tasks. `params` and `alternatives`. |
| `@todo_list` | The goal. A call, a `goal`, or a `multigoal`. |

A body step is one of two shapes.

```elixir
%{eval: %{type: "math/eq", a: %{pointer_get: "/have/mesh"}, b: true}}
%{pointer_set: "/have/mesh", value: true}
```

The first is a guard, and the second is an effect. A guard that fails
makes the planner take another alternative.

A problem is a second module. It sets `@source` to the domain name, it
overrides the `@variables` keys it cares about, and it carries its own
`@todo_list`.

## Four rules that catch a writer out

**No `:string` type.** The vocabulary comes from glTF Interactivity:
`bool`, `int`, `float`, `float2`, `float3`, `float4`, the matrices,
and `ref`. A file handle, a stage name, and a format are each `:ref`,
which is an opaque value compared for equality.

**No `:enum` type.** A named class is capability data, and it belongs
in the top-level `capabilities` key.

**A goal method is an ordinary method named after its state
variable.** To let a problem ask for `/have/psd`, the domain needs a
method called `have` with `params: [:artifact, :desired]`. Without it
the goal has nothing to decompose.

**A keyword colon needs a space before a bracket.** Write
`todo: [type: list]`, and never `todo:[type: list]`.

## Make the memory a planning result

Write `a_load` and `a_unload` as real actions. The peak memory is then
something the planner decides, and not an accident of call order.

```elixir
a_load: %{
  params: [:component],
  body: [
    %{eval: %{type: "math/eq", a: %{pointer_get: "/loaded/{component}"}, b: false}},
    %{pointer_set: "/loaded/{component}", value: true}
  ]
}
```

RFD 0027 gives the budget these actions serve.

## Put a safety rule in a guard

A guard the planner enforces beats a comment nobody reads.

RFD 0047 is the example. Inversion is lossy, thus `a_decode` requires
`/have/preserved_outside`, and `a_splice` sets it. No plan can move a
vertex outside the mask, because no plan can reach the decode first.

## Branch on a variable, and not on a second domain

Two domains that share every stage will drift. Give the domain a
`:ref` variable, and give the method one alternative per value.

RFD 0047 and RFD 0048 share one domain. `mode.conditioning` picks the
branch, and each alternative checks it. The two plans differ in
exactly one step.

## Save the plan

Write the result to `plan.ex` beside the domain. A cold start then
needs no planner and no network.

Mark it GENERATED, and never edit it by hand. A hand-edited plan can
hold a step order the guards forbid.

Regenerate when `domain.ex` changes. Nothing enforces that yet, so the
staleness is on the writer.

## Replanning

`plan` takes `plan_json` and `fail_step`. A caller that loses a stage
resumes from that step, and the work before it stands.

That is the reason a composite is a domain and not a script.

## Maintenance

Run these before a commit. prek runs them too.

```bash
mix format --check-formatted        # .formatter.exs covers decisions/**/*.ex
elixir scripts/check-elixir-parses.exs
prek run --all-files
```

A domain is real Elixir, thus `Code.string_to_quoted/1` catches a
syntax fault long before the planner does.

## Reading a plan response

```json
{"plan": [["a_load", "lama"], ["a_inpaint"]],
 "temporal": {"consistent": true, "total": "PT0S", "steps": [...]}}
```

`consistent` false means the durations conflict. Every action here
declares no `duration`, thus every total is `PT0S`. Add `duration` in
ISO 8601, such as `"PT5M"`, when the schedule matters.

An empty `plan` means no alternative satisfied its guards. Check the
`init` values in the problem first, because a guard that reads an
unset key fails quietly.

## Where things are

| Path | Holds |
| ---- | ----- |
| `decisions/00NN-*/domain.ex` | The domain. |
| `decisions/00NN-*/problem.ex` | The problem. |
| `decisions/00NN-*/plan.ex` | The solved plan, generated. |
| `decisions/0037-*/README.md` | Why composites are domains. |
| `.formatter.exs` | Formatter scope. |

Upstream is github.com/taskweft/taskweft. `docs/rectgtn.md` explains
the model, and `priv/schemas/rectgtn_domain.schema.json` gives the
JSON-LD shape.

The README there says the planner moves to an s7-Lisp-in-libriscv
stack. That plan is vetoed, and the line is stale. taskweft is the
planner.
