# RFD 0054: The planner inside the studio core

**State:** discussion
**Scope:** `weftspun_studio/`

## Problem

`extension/` ran Elixir in an editor panel, through Popcorn and
AtomVM. It proved the pipeline, and it could not ship.

AtomVM needs `SharedArrayBuffer`, thus the page must be cross-origin
isolated. An editor webview is not isolated, and an extension cannot
set the headers. The panel worked only with `codium --enable-coi`.

The proof stands, and the vehicle does not.

## Decision

Delete `extension/`. Put the planner inside `weftspun_studio`, which
RFD 0019 already makes the API server.

RFD 0023 gives the shape, and this RFD does not restate it.

## A second application was the wrong answer first

This RFD first built `cms/`, a new Elixir application. That was a
mistake, and the record of it matters more than the correction.

`weftspun_studio` already held ports, adapters, an HTTP router, Ecto,
and CockroachDB. RFD 0019 and RFD 0020 record it. The second
application duplicated every one of those.

Three parts were new, and only those moved:

| Part                | Where it lives now                        |
| ------------------- | ----------------------------------------- |
| Planning documents  | `priv/domains`, `priv/problems`           |
| `Ports.Planner`     | Beside the other ports                    |
| `TaskweftPlanner`   | Beside the other adapters                 |

`cms/` is deleted. That also settles the overlap with RFD 0023, which
this RFD carried while it described a parallel application.

## Mock every port, and keep the documents real

Every port is a `Mox` mock. A mock derives from the behavior, thus a
port that gains a callback breaks its mock when it compiles.

The planning documents are the exception. A mocked domain proves
nothing about the pipeline, because the domains are the pipeline.
`pipeline_test.exs` mocks nothing, and it runs the real planner over
the real documents.

## The measured plans

| Pipeline     | Steps | Composes                                  |
| ------------ | ----: | ----------------------------------------- |
| content_only |     3 | the base alone                            |
| mesh         |     7 | base and stage_mesh                       |
| avatar       |    10 | base, stage_mesh, stage_rig, and a problem|

The avatar plan is the evidence. `stage_rig` calls `a_generate_mesh`,
which `stage_mesh` defines, and that resolves only because the merge
unions the actions of every document first.

## Three faults came out of this

The work needed three fixes to taskweft, and each came from use and
not from reading. Each one answered `no_plan`, which names nothing.

- Composition did not exist. `merge/2` was private to the CLI, and it
  took one domain and one problem. PR 207.
- A shared variable replaced instead of merging its keys, thus the
  base lost the keys its own guards read. PR 208.
- A goal serialized `eq: true` as the string `"true"`, thus it never
  matched a boolean in state. PR 209.

PR 207 also rewrote the DSL diagnostics. A domain written against an
API that does not exist compiled without complaint, and returned an
empty document.

## Two routes

`/api/v1/pipelines` lists what this deployment knows.
`/api/v1/pipelines/:name/plan` solves one and runs nothing, thus a
caller sees the plan before it pays for the models.

`Pipeline.parse/1` takes `String.to_existing_atom/1`. An HTTP caller
must not fill the atom table, which never shrinks.

## Related

RFD 0019 makes this the API server. RFD 0023 gives the shape. RFD 0037
gives the composite convention. RFD 0055 selects the worker host.
