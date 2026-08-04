# Changelog

## 0.2.2

- The panel now names the reason it cannot start, and it no longer
  waits 30 seconds for a timeout. AtomVM needs `SharedArrayBuffer`,
  which needs a cross-origin isolated page. An editor webview is not
  isolated, thus the panel asks for `codium --enable-coi`.
- The panel reports the WebGPU adapter even when the VM cannot start,
  because WebGPU needs no isolation.
- `verify-csp.mjs` takes `WEFTSPUN_NO_COI=1`, which drops the isolation
  headers and matches what a webview gives.

## 0.2.1

- Fixes a panel that stayed at "Starting the Elixir VM". The policy
  carried a nonce in `script-src`, and a nonce makes the browser ignore
  `unsafe-inline`. Popcorn writes an inline module script into the
  hidden `srcdoc` iframe that holds the VM. That frame inherits the
  panel policy, thus the nonce blocked the VM.
- `worker-src` now names the webview origin. AtomVM starts its worker
  from `AtomVM.mjs`, and `blob:` alone blocked it.
- Adds `npm run test:csp`, which runs the bundle under the same policy
  the panel writes.

## 0.2.0

- Elixir now generates WGSL, WebGPU runs it, and Elixir checks the
  result. `popcorn/lib/weftspun_popcorn/wgsl.ex` holds the generator.
- The panel reports the WebGPU adapter, thus it says what the editor
  offers.
- 4 kernels run: vector add, vector multiply, relu, and scale by 3.
- `verify-bundle.mjs` takes the full Chromium build. The headless shell
  gives `navigator.gpu` and then no adapter.

## 0.1.0

- First release.
- Adds the `Weftspun: Run Minimal Test` command. It opens a panel and
  runs the checks in `WeftspunPopcorn` as Elixir, on AtomVM, in
  WebAssembly.
- Builds with Popcorn 0.3.2.
