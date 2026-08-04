# Weftspun 3D Studio

Runs the Weftspun minimal test as real Elixir, inside an editor panel.

The checks do not run in JavaScript. [Popcorn][popcorn] compiles the
Elixir in `popcorn/lib/` to an AtomVM bundle, and the panel starts that
bundle in WebAssembly. A result in the panel is a result from the BEAM.

The extension targets VSCodium. It uses no proprietary API, and it
publishes to Open VSX. It runs in Visual Studio Code as well.

## Use

Open the command palette and run **Weftspun: Run Minimal Test**.

The panel reports the Elixir version, the OTP release, and the machine.
The machine reads `ATOM`, which is AtomVM and not the desktop BEAM.

| Check         | What it proves                                 |
| ------------- | ---------------------------------------------- |
| arithmetic    | Integer arithmetic and `Enum`.                  |
| binaries      | `String` on binaries.                           |
| pattern match | Tuple and list destructuring.                   |
| map update    | `Map.update!` on a map.                         |
| processes     | `spawn`, `send`, and `receive` in the VM.       |
| reduce        | `Enum.reduce` with an accumulator.              |

The process check matters most. A plain expression would run without a
scheduler, but a message round trip needs AtomVM to run two processes.

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
npm test          # the bundle rules, with no editor and no browser
npm run test:browser   # runs the built bundle in Chromium, and reports each check
```

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
src/extension.js      the command
src/popcornPanel.js   the webview, its CSP, and the artifact URIs
src/popcornBundle.js  where the build is, and what it is missing
popcorn/lib/          the Elixir that runs the checks
popcorn/assets/       the page that starts the VM
popcorn/dist/         build output, which the panel loads
```

`popcornBundle.js` takes no editor API, which is why `test/` can cover
it with `node --test`.

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
