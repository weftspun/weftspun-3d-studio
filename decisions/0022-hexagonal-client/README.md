# RFD 0022: A hexagonal client for the headless studio API

**State:** discussion
**Scope:** `src/core/`

## Problem

RFD 0019 makes the studio core an API server. The browser client
becomes one consumer of that API. The client is not built that way
today.

The client holds 333 source files. 39 of them call the network
directly, through `axios` or `fetch`. Domain logic, network calls,
React state, and three.js all sit in the same modules. A rule such
as "which model serves this task type" lives beside the code that
fetches a job. A test of that rule must load React and the network.
A second consumer, such as the XR client, cannot reach the rule at
all.

The model catalog shows the problem. `src/library/aiModelsCatalog.js`
holds a fixed list of 28 models. The Elixir core holds the same
list, from RFD 0016. The two already drifted once:
`qwen_q4_k_m_image_edit` reached the inventory and never reached the
client.

## Decision

Grow a hexagonal core inside `src/core/`. It takes the same ports
and adapters split the Elixir side uses: a `domain/` of pure rules,
`ports/` of contracts, and `adapters/` one per data source.

The client keeps every other file. This is a strangler fig, as RFD
0019 records. Nothing moves until a port covers it.

See `DETAILS.md` for the full shape, why a port is a contract test,
the first port this RFD builds, the method, and the risks.
