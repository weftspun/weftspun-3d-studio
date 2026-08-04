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

A manifest asks the question two ways, and neither one is by address.
A locked collection asks which traits of that collection the holder
has. A purchase definition asks which traits the holder bought. Both
answer with the same shape, thus both belong on the same port.

`OwnedAssetSource`:

| Function                      | Returns                               |
| ----------------------------- | ------------------------------------- |
| `isEnabled()`                 | False when no chain is configured.    |
| `listCollections()`           | The collections the client knows.     |
| `listOwnedTraitIds(address)`  | The trait ids one address holds.      |
| `listCollectionTraits(query)` | The traits a locked collection frees. |
| `listPurchasedTraits(query)`  | The traits a purchase frees.          |

The last two answer with `{ownedIDs, ownedTraits}`, which is the shape
`unlockTraits` reads. An incomplete query frees nothing, and no adapter
rejects. A picker that cannot reach a chain shows the locked set, and
the page still loads.

`nullOwnedAssetSource` is the default. It reports `isEnabled()` as
false and returns empty lists. This is the headless case: content
serves with no wallet, no network, and no chain library.

`walletOwnedAssetSource` reads the real collections, through the
modules that now live in `src/chain/`.

`VITE_ENABLE_CHAIN` turns the wallet adapter on. Without it the
client takes the null adapter, so a content-only deployment carries
no chain behavior.

### A test guards the boundary

A rule that only a document states is a rule that decays. So the
boundary ships as a test. It reads every file under `src/core/` and
fails when one imports a chain library or a `src/chain/` module.

`src/library/` still holds violations. The test lists them, and that
list may only shrink. A new violation fails the build.

## Method

Red, green, refactor, as RFD 0022 sets out. The RFD is the first red.

1. **Red.** This document, then the port the contract failing test and the
   boundary failing test.
2. **Green.** Failing tests pass. The two adapters, and the move into `src/chain/`.
3. **Refactor.** Point content code at the port, one caller at a
   time, and shorten the violation list.

## What this does not do

It does not change what the client does. The wallet adapter runs the
same code as before, from a new place.

It does not rewrite `characterManager.js`. That module mixes avatar
loading with minting, and minting is commerce. The boundary test
records it instead, so the debt stays visible and cannot grow.

It does not port three.js, WebXR, or rendering.

It does not fix the test failures the client already carries. Those
predate the rebrand, and RFD 0022 records them. The Status section
gives the measured count.

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

- `src/chain/` holds the 9 chain modules. 11 files changed import
  path, and 5 sibling imports inside the moved files moved with them.
- `OwnedAssetSource` ships as a contract test.
  `nullOwnedAssetSource` and `walletOwnedAssetSource` both pass it.
- The wallet adapter loads the wallet stack through a dynamic
  import. A static import pulled the VRM and three.js exporters into
  every consumer, and those run work at load time.
- `src/composition.js` is the composition root, outside the core. It
  takes the null adapter unless `VITE_ENABLE_CHAIN` is `1`.
- The boundary ships as `src/core/architecture.test.js`, with 10
  tests.
- 37 new tests. The build passes, and the suite holds at the failure
  count it had before. The refactor step below gives the measured
  numbers, and corrects the count this line first recorded.

The boundary test needed two corrections, and both matter.

It first derived the source directory from `import.meta.url`. Vitest
rewrites that to a served path, thus every read failed. The directory
walk returned an empty list, and all six tests passed while they read
nothing. The walk now throws for a missing directory, and two tests
assert that the walk found real files.

It also counted a commented-out import as a dependency. That put
`characterManager.js` on the list of modules that import a chain
library, which was wrong.

### The refactor step

The first move put `aigcRigContract.js` in `src/chain/`. That module
validates a rig contract, not a blockchain contract. Its name put it
there, and it pulled three.js and `rigBoneUtils.js` in behind it. It
is back in `src/library/`, where the code it reads is. A module
belongs in `src/chain/` for what it imports, and not for what it is
called. A test now holds that rule: `src/chain/` may import nothing
that renders.

That correction alone took `sceneManager.js` off the leak list,
because that module never reached a chain.

`CharacterManifestData.js` now takes an `OwnedAssetSource`, and
`new WalletCollections()` is gone. `ManifestDataManager` passes the
source to each manifest it builds, and `characterManager.js` asks the
composition root for it. The source arrives as a promise, because the
root builds the wallet adapter through a dynamic import, and a
constructor cannot wait.

The port did not fit the caller at first. It answered by address, and
a manifest asks by collection lock or by purchase definition. So the
port took two more functions, and the contract test holds them.

Two faults came out of the move:

- The old purchase read got `undefined` for `delegateAddress`, every
  time. `SolanaPurchaseAssets` dropped the field, and the read asked
  for it. The field now goes through. A manifest without the field
  reads as it did before.
- `getSolanaPurchasedAssets` answers with `null` when the read fails,
  and `unlockTraits` read `null.ownedIDs`. The port answers with one
  shape, thus the fault cannot return.

The boundary test compared a path from `node:path` with a name written
with forward slashes. On Windows the two never matched, and the leak
list did nothing. The test normalizes the separator now. Two boundary
tests failed on Windows before this step, and both pass now.

`characterManager.js` also held a `walletCollections` field that no
code read. It is gone.

The refactor step adds 23 test cases. The port contract takes 5 of
them, and each of the two adapters runs the contract. The wallet
adapter takes 4 more, the manifest takes 7, the composition root takes
1, and the boundary takes 1.

Open:

- `characterManager.js` and `pages/Load.jsx` still reach chain code.
  `characterManager.js` mints, and `pages/Load.jsx` reads a contract
  with ethers. Neither is a content concern. The boundary test holds
  that list, and it may only shrink.
- `ownedNFTTraitIDs.js` sits in `src/chain/` and reaches no chain. It
  turns metadata into trait ids, which is a content rule, thus it
  belongs in `domain/`. It reads `DOMParser` for one data source, and
  that must move first.
- Ports for the job lifecycle and for assets.
- The app shell runs work at load time, through two paths. The XR
  world package draws a cursor texture on a canvas when it loads.
  `download-utils.js` builds the VRM exporter, and that starts KTX
  tools. A shell that shows no XR and exports nothing still pays for
  both. This is the cost the wallet adapter already avoids with a
  dynamic import.
- `src/components/TaskManager.jsx` line 1163 imports
  `prepareGlbForApiUpload` from `glbCompress.js`, and that module does
  not export it. The upload path throws. A test records this.

### The test suite, sorted by concern

The suite mixed concerns, and that hid what was broken:

- Playwright owns `tests/e2e`, and the vitest include pattern matches
  `.spec.js`. Vitest collected 3 Playwright specs and failed on them.
  `vitest.config.js` excludes them now.
- `tests/setup.js` gave no 2D canvas context, no `ResizeObserver`, and
  no `IntersectionObserver`. The app shell needs all three, thus its
  test file threw before one test ran.
- Two mocks were closed lists. The `three` mock threw for each symbol
  it did not name, and the `SceneContext` mock threw for the context
  object. Both take the real module as a base now.

That work removed 6 failed files and added 45 passing tests. It
changed no source file, except for the RFD itself.

The suite ran on Windows for this step. Before the step it gave 27
failures in 547 tests. After the step it gives 25 failures in 570
tests. The 2 failures that went away are the 2 boundary tests above.
No test that passed before fails now.

The earlier count of 33 failures was wrong. It counted lines of
`FAIL` output, and vitest prints one such line for a test and one for
a file. The count of failed tests is what matters, and it was 27.
