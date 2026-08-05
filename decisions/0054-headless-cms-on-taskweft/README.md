# RFD 0054: Headless CMS on taskweft

**State:** discussion
**Scope:** `cms/`

## Problem

`extension/` ran Elixir in an editor panel, through Popcorn and
AtomVM. It proved the pipeline, and it could not ship.

AtomVM is an emscripten build with pthreads. It needs
`SharedArrayBuffer`, thus the page must be cross-origin isolated. An
editor webview is not isolated, and an extension cannot set the
headers. The panel worked only with `codium --enable-coi`.

The proof stands, and the vehicle does not.

## Decision

Delete `extension/`. Build the content system as an Elixir
application in `cms/`, in the shape RFD 0023 gives.

taskweft is a mandatory dependency. The pipeline order lives in a
RECTGTN domain, thus a build without the planner has no pipeline.

## The layout

```
cms/lib/weftspun_cms/
  composition.ex        the composition root. The only module that
                        picks an adapter.
  content.ex            the API of the content system.
  core/
    domain/    pure rules. No I/O.
    ports/     behaviours, one per side.
    adapters/  the implementations.
  planning/
    loader.ex  reads the documents from priv/.
cms/priv/
  domains/     content_lifecycle, stage_mesh, stage_rig
  problems/    avatar
```

The composition root sits outside `core/`, as RFD 0023 requires.

## Mock every port, and keep the documents real

Every port is a `Mox` mock. A mock derives from the behaviour, thus a
port that gains a callback breaks its mock when it compiles.

The planning documents are the exception. A mocked domain proves
nothing about the pipeline, because the domains are the pipeline.
`composition_of_domains_test.exs` mocks nothing and runs the real
planner over the real documents.

## The composition of domains

Three documents compose for the avatar pipeline.

| Document          | Adds                             |
| ----------------- | -------------------------------- |
| content_lifecycle | stage, validate, publish         |
| stage_mesh        | the mesh, and it overrides       |
| stage_rig         | the rig, and it overrides again  |
| avatar (problem)  | the goal, and the VRM output     |

Order carries meaning. A later document wins, thus the base leads and
the problem trails.

`stage_rig` calls `a_generate_mesh`, which `stage_mesh` defines. That
resolves because the merge unions the actions of every document before
the planner sees them. Two pipelines that both make a mesh name one
document, and no copy drifts.

## Three faults came out of this

The work needed three fixes to taskweft, and each one came from use
and not from reading.

- Composition did not exist. `merge/2` was private to the CLI, and it
  took one domain and one problem. Upstream PR 207 adds it.
- A shared variable replaced instead of merging its keys. The base
  declared `have` with `source`, the mesh stage declared `have` with
  `mesh`, and the base keys went away. Every guard that read one
  failed, and the planner answered `no_plan`. PR 208 fixes it.
- A goal serialized `eq: true` as the string `"true"`. The state holds
  a boolean, thus the goal never matched. PR 209 fixes it.

Each fault answered `no_plan`, which names nothing.

## What this does not do

It does not serve HTTP yet. The API is a module, and a Plug router is
the next step.

It carries no job store and no asset store. Both ports exist, and both
have mocks. Neither has an adapter.

It does not run the models. A Cog runs each one, and RFD 0036 records
that packaging.

## Related

RFD 0023 gives the shape. RFD 0037 gives the composite convention.
RFD 0053 gives the asset format. RFD 0036 gives the Cog packaging.
