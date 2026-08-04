# RFD 0023: Ports and adapters, in the headless content style

**State:** discussion
**Scope:** `src/core/`, `src/chain/`

## Problem

RFD 0019 makes the studio core an API server. RFD 0022 started a
hexagonal core in the client, with one port for the model catalog.

The rest of the client keeps the old shape. Domain rules, network
calls, chain calls, React, and three.js share modules. Two problems
follow from that, and this RFD takes both.

**The layout does not say what a module is.** `src/library/` holds
507 line catalogs beside wallet readers beside three.js helpers. A
reader cannot tell a rule from an adapter.

**The chain reaches into content.** Four modules of content code
read wallet data. `characterManager.js` imports `mint-utils`,
`walletCollections`, and `ownedNFTTraitIDs`.
`CharacterManifestData.js` imports `walletCollections`.
`rigBoneUtils.js` and `sceneManager.js` import `aigcRigContract`.

The reach is indirect. Only four modules import a chain library
itself: `mint-utils.js`, `thirdwebInAppWallet.js`,
`thirdwebSmartWallet.js`, and `pages/Load.jsx`. The content modules
sit one step behind those, which is why the dependency is easy to
miss.

Avatar authoring is content work. It now needs a wallet.

## Decision

Arrange the code the way a headless content system is arranged, and
take content as the only concern.

A headless content system holds content, and answers for it over an
API. It does not render. It does not hold a wallet. Every other
system is a client of it.

That gives the layout:

```
src/composition.js   the composition root. The only file that
                     picks adapters.
src/core/
  domain/     pure content rules. No I/O, no React, no three.js.
  ports/      contracts, each one a test.
  adapters/   content adapters that need no chain.
src/chain/    every module that imports a chain library,
  adapters/   and the adapters that need one.
```

The composition root sits outside `src/core/`. It must know every
side, and the core may not reach a chain, so the root cannot live
inside the core.

Two rules hold it together:

- `domain/` may import from `domain/` only.
- **Nothing in `src/core/` may import a chain library, or any
  module in `src/chain/`.**

The client keeps every other file. This is a strangler fig, as RFD
0019 records. A module moves when a port covers it, and not before.

### Content, and not content

The split is by concern, not by technology.

| Concern                       | In scope | Where                     |
| ----------------------------- | -------- | ------------------------- |
| Which models exist            | Yes      | `CatalogSource`, RFD 0022 |
| Which assets an owner may use | Yes      | `OwnedAssetSource`        |
| Minting, payment, x402        | No       | `src/chain/`              |
| Rendering, three.js, WebXR    | No       | stays in `src/library/`   |

Rendering is not a content concern, so this RFD leaves it. Commerce
is not a content concern either. Minting writes to a chain, and a
content server never writes to a chain.

### The port for owned assets

Content needs one answer from a chain: **which assets may this owner
use?** A trait an owner holds is a trait a picker may offer. That is
a content availability question, and it is the whole of the port.

`OwnedAssetSource`:

| Function                     | Returns                            |
| ---------------------------- | ---------------------------------- |
| `isEnabled()`                | False when no chain is configured. |
| `listCollections()`          | The collections the client knows.  |
| `listOwnedTraitIds(address)` | The trait ids one address holds.   |

`nullOwnedAssetSource` is the default. It reports `isEnabled()` as
false and returns empty lists. This is the headless case: content
serves with no wallet, no network, and no chain library.

`walletOwnedAssetSource` reads the real collections, through the
modules that now live in `src/chain/`.

`VITE_ENABLE_CHAIN` turns the wallet adapter on. Without it the
client takes the null adapter, so a content-only deployment carries
no chain behaviour.

### A test guards the boundary

A rule that only a document states is a rule that decays. So the
boundary ships as a test. It reads every file under `src/core/` and
fails when one imports a chain library or a `src/chain/` module.

`src/library/` still holds violations. The test lists them, and that
list may only shrink. A new violation fails the build.

## Method

Red, green, refactor, as RFD 0022 sets out. The RFD is the first red.

1. **Red.** This document, then the port contract test and the
   boundary test.
2. **Green.** The two adapters, and the move into `src/chain/`.
3. **Refactor.** Point content code at the port, one caller at a
   time, and shorten the violation list.

## What this does not do

It does not change what the client does. The wallet adapter runs the
same code as before, from a new place.

It does not rewrite `characterManager.js`. That module mixes avatar
loading with wallet reads, and untangling it needs its own change.
The boundary test records it instead, so the debt stays visible and
cannot grow.

It does not port three.js, WebXR, or rendering.

It does not fix the 33 test failures the client already carries.
Those predate the rebrand, and RFD 0022 records them.

## Risks

A moved module is a changed import path. The move touches 14 import
statements. The suite is the check, and it must hold at the count it
had before.

The null adapter changes what a picker shows when no chain is
configured. It shows no owned traits, which is right for a headless
deployment. The wallet adapter restores the old answer.

`src/library/` keeps a copy of rules that also live in `domain/`,
until each caller moves. The port marks which one is current.

## Status

Done:

- `src/chain/` holds the 10 chain modules. 11 files changed import
  path, and 5 sibling imports inside the moved files moved with them.
- `OwnedAssetSource` ships as a contract test.
  `nullOwnedAssetSource` and `walletOwnedAssetSource` both pass it.
- The wallet adapter loads the wallet stack through a dynamic
  import. A static import pulled the VRM and three.js exporters into
  every consumer, and those run work at load time.
- `src/composition.js` is the composition root, outside the core. It
  takes the null adapter unless `VITE_ENABLE_CHAIN` is `1`.
- The boundary ships as `src/core/architecture.test.js`, with 9
  tests.
- 37 new tests. The build passes, and the suite holds at 33
  failures, the count it had before.

The boundary test needed two corrections, and both matter.

It first derived the source directory from `import.meta.url`. Vitest
rewrites that to a served path, so every read failed, the directory
walk returned an empty list, and all six tests passed while reading
nothing. The walk now throws for a missing directory, and two tests
asserts that the walk found real files.

It also counted a commented-out import as a dependency. That put
`characterManager.js` on the list of modules that import a chain
library, which was wrong.

Open:

- `characterManager.js`, `CharacterManifestData.js`,
  `sceneManager.js`, and `pages/Load.jsx` still reach chain code.
  The boundary test holds that list, and it may only shrink.
- No content code calls `OwnedAssetSource` yet. The port exists, and
  the callers move one at a time.
- Ports for the job lifecycle and for assets.
