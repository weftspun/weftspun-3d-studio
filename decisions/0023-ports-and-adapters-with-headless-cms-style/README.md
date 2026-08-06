# RFD 0023: Ports and adapters, in the headless content style

**State:** discussion
**Scope:** `src/core/`, `src/chain/`

## Problem

RFD 0019 makes the studio core an API server. RFD 0022 started a
hexagonal core in the client, with one port for the model catalog.
The rest of the client keeps the old shape: domain rules, network
calls, chain calls, React, and three.js share modules.

**The layout does not say what a module is.** `src/library/` holds
507-line catalogs beside wallet readers beside three.js helpers. A
reader cannot tell a rule from an adapter.

**The chain reaches into content.** Four modules of content code
read wallet data, one step behind the four modules that import a
chain library directly. Avatar authoring is content work, and it now
needs a wallet.

## Decision

Arrange the code the way a headless content system is arranged, and
take content as the only concern. Such a system holds content and
answers for it over an API. It does not render, and it does not
hold a wallet.

Two rules hold the split together: `domain/` may import from
`domain/` only, and nothing in `src/core/` may import a chain
library or a `src/chain/` module.

The client keeps every other file. This is a strangler fig, as RFD
0019 records. A module moves when a port covers it, and not before.

See `DETAILS.md` for the full layout, the content/not-content split,
the `OwnedAssetSource` port, the boundary test, the method, the
risks, and the verified status.
