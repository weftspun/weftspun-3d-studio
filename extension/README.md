# Weftspun 3D Studio

Runs the Weftspun minimal test as real Elixir, on a real GPU, inside an
editor panel.

[Popcorn][popcorn] compiles the Elixir in `popcorn/lib/` to an AtomVM
bundle, and the panel starts that bundle in WebAssembly. Elixir then
generates WGSL, WebGPU runs it, and Elixir checks what came back.

Elixir keeps what matters. It writes the shader, it computes the
expected values, and it decides pass or fail. WebGPU only executes.

The extension targets VSCodium. It uses no proprietary API, and it
publishes to Open VSX. It runs in Visual Studio Code as well.

## The editor must be cross-origin isolated

AtomVM is an emscripten build with pthreads. It needs
`SharedArrayBuffer`, and a browser gives that only to a page that is
cross-origin isolated. An editor webview is not isolated by default,
and an extension cannot set the headers that would isolate it.

Start the editor with the flag, and the panel works:

```bash
codium --enable-coi
```

Without the flag the panel reports the reason, and it still reports the
GPU adapter, because WebGPU needs no isolation.

Three other routes are closed today:

- AtomVM refuses Node with `environment detection error`, thus the
  extension host cannot hold the VM. The build targets web and worker.
- An iframe cannot gain isolation when the top document lacks it, thus
  a local server with the headers does not help inside a webview.
- Popcorn 0.3.2 ships one AtomVM build, and it has no single-threaded
  variant.

## Use

Open the command palette and run **Weftspun: Run Minimal Test**.

The panel reports the Elixir version, the OTP release, and the machine.
The machine reads `ATOM`, which is AtomVM and not the desktop BEAM.

| Check            | What it proves                              |
| ---------------- | ------------------------------------------- |
| arithmetic       | Integer arithmetic and `Enum`.               |
| binaries         | `String` on binaries.                        |
| processes        | `spawn`, `send`, and `receive` in the VM.    |
| wgsl codegen     | Elixir emitted a kernel with a workgroup.    |
| webgpu adapter   | The panel found a usable GPU.                |
| vector add       | `a[i] + b[i]` over 256 elements.             |
| vector multiply  | `a[i] * b[i]` over 256 elements.             |
| relu             | `max(x, 0.0)` over 256 signed elements.      |
| scale by 3       | `x * 3.0` over 256 elements.                 |

The process check proves the scheduler, because a message round trip
needs AtomVM to run two processes. The kernel checks prove the whole
pipeline, because the expected values come from the BEAM.

Without a GPU the panel reports the adapter check as a failure, and the
Elixir checks still run.

## Build

The panel loads `popcorn/dist`, and that folder is build output. Build
it before you package or debug the extension:

```bash
npm install
npm run build
```

Popcorn 0.3.2 raises unless it sees OTP 26.0.2 and Elixir 1.17.3.
`popcorn/mise.toml` pins both, thus [mise][mise] provisions them:

```bash
mise install
```

`npm run build` calls mise when it finds it. Without mise, the build
uses the `mix` on `PATH`, and that `mix` must be the pinned pair.

## Test

```bash
npm test               # the bundle rules, with no editor and no browser
npm run test:browser   # runs the built bundle in Chromium
npm run test:csp       # runs it under the panel's security policy
```

`npm run test:csp` matters most. The panel always carries a policy, and
a policy that blocks the runtime leaves the panel at "Starting the
Elixir VM". This script serves the same policy `popcornPanel.js`
writes, thus it catches that before an install does.

`npm run test:browser` needs a browser once:

```bash
npx playwright install chromium
```

## Package

```bash
npm run package           # writes a .vsix
npm run publish:openvsx   # publishes to Open VSX
```

`.vscodeignore` keeps `popcorn/dist` and drops the Elixir sources, the
Mix build, and `node_modules`. The bundle and the AtomVM runtime are
about 11 MB together, and they are most of the package.

## Layout

```
src/extension.js         the command
src/popcornPanel.js      the webview, its CSP, and the artifact URIs
src/popcornBundle.js     where the build is, and what it is missing
popcorn/lib/wgsl.ex      generates the WGSL, and checks the answers
popcorn/lib/             the Elixir that drives the checks
popcorn/assets/webgpu.js binds buffers, dispatches, and reads back
popcorn/assets/          the page that starts the VM
popcorn/dist/            build output, which the panel loads
```

## Why the kernels are naive

One invocation handles one element. The kernel does no tiling, no
staging, and no vectorization. That separates two hard parts. The
orchestration goes from Elixir to WebAssembly to WebGPU and back. The
graphics work is a fast kernel.

A faster kernel is a later change to `wgsl.ex` alone. The pipeline
around it does not move when the kernel does.

## How the two sides talk

`Popcorn.Wasm.run_js/3` is synchronous, and every WebGPU call is
asynchronous, thus Elixir cannot await a dispatch. JavaScript drives
instead, and calls into Elixir with `popcorn.call`:

1. `["vm_checks"]` returns the checks that need no GPU.
2. `["gpu_plan"]` returns the WGSL, the inputs, and the output length.
   The expected values stay in Elixir.
3. `["gpu_verify", name, values]` returns the verdict.

`popcornBundle.js` takes no editor API, which is why `test/` can cover
it with `node --test`.

## The panel security policy

Three permissions in `popcornPanel.js` are not decoration. Each one
answers a block that stopped the VM:

- `script-src` uses `unsafe-inline` and carries no nonce. Popcorn runs
  the VM in a hidden `srcdoc` iframe, and it writes an inline module
  script into that frame. The frame inherits the panel policy. A nonce
  in `script-src` makes the browser ignore `unsafe-inline`, thus a
  nonce blocks the frame that holds the VM.
- `worker-src` names the webview origin, and not only `blob:`. AtomVM
  starts its worker from `AtomVM.mjs`.
- `wasm-unsafe-eval` is for AtomVM. `unsafe-eval` is for the bridge,
  which evaluates the function Elixir sends through `run_js`.

## Notes on Windows

The OTP 26.0.2 archive for Windows carries an `erl.ini` that points at
the machine that built it. A tool that unpacks the archive, and does
not run the OTP installer, leaves that file wrong, and every `erlc`
through a shell then fails with `Could not load module ...erlexec.dll`.
Rewrite `erts-14.0.2/bin/erl.ini` with the real paths, and double every
backslash.

## License

MIT. See `LICENSE`.

[popcorn]: https://github.com/software-mansion/popcorn
[mise]: https://mise.jdx.dev
