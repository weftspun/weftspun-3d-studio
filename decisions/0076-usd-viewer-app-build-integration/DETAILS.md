# RFD 0076 details: the shape, the patch, the bug Playwright caught, and what verified

## Why an app, not a bake-in

An earlier pass this session baked `usd_viewer_app`'s build into
`weftspun_studio`'s own `Dockerfile`/`Dockerfile.fly`, a `gallery-assets`
Node stage `COPY`ed into `priv/static/gallery`. That version worked,
verified with a real `docker build --target gallery-assets`, but the
user asked for the other shape instead: `usd_viewer_app` as its own
deployed app, in the ports-and-adapters style RFD 0022/0023 already
give the browser client, and the separate-deploy pattern
`character_taxonomy/` already gives a second Elixir app. This RFD
records that shape, not the bake-in.

## apps/, one directory for every deployed app

A second move followed the same reasoning further: `weftspun_studio`
itself moved from the repo root into `apps/weftspun_studio/`,
alongside `apps/character_taxonomy/` and the new
`apps/usd_viewer_app/`. This directly reverses RFD 0060's own
decision ("weftspun_studio/ becomes the repository root... The
end-shape system was the guest. The system it replaces was the
host."). RFD 0060's reasoning does not carry over: with three
independently deployed apps now, not one strangler-fig core and a
legacy client, "which one is the host" stops applying. Every
`.build`/`.container` Quadlet path, `Dockerfile.fly`'s
`working-directory` in `.github/workflows/deploy-fly.yml`,
`.pre-commit-config.yaml`'s file patterns, and `scripts/{ci,studio-test,deploy-weftspun-quadlet}.sh`
were updated to the new paths, and `mix compile` was re-verified
from `apps/weftspun_studio/` after the move. `weftspun_studio`'s own
`.formatter.exs` split in two: a repo-root one for `decisions/**` (no
single app owns the taskweft domains), and `apps/weftspun_studio/.formatter.exs`
for the app's own `{config,lib,test}`, since a bare `mix format`
needs no `mix.exs` to run but does read `.formatter.exs` from its own
working directory.

## The independent app

`usd_viewer_app/server.js`, new, is the whole runtime: no framework,
no dependency, `node:http` and `node:fs` serving `dist/` under
`/gallery/*`, plus `/health`. `usd_viewer_app/Dockerfile`, new,
builds `dist/` in one Node stage and runs `server.js` in a second.
`usd_viewer_app/fly.toml`, new, deploys it as its own Fly app,
`weftspun-usd-viewer`, with no public port; `weftspun_studio`
reaches it over Fly's private 6PN network. Two new Quadlet files,
`deploy/quadlet/weftspun-usd-viewer.{build,container}`, give the
same shape for the Podman path, `weftspun.container` reaching it by
`ContainerName` on `weftspun.network`.

## The port and the adapter

`WeftspunStudio.Ports.GallerySource` (new) declares one callback,
`fetch(state, path)`, returning `{:ok, body, content_type}` or
`:error`. `WeftspunStudio.Adapters.HttpGallery` (new) implements it
with `Req.get(base_url() <> path, decode_body: false)`.
`decode_body: false` matters: Req auto-decodes a JSON body by
content type, which would corrupt the `.wasm`/`.usdz`/binary payloads
this proxies. `router.ex`'s gallery routes changed from
`Plug.Static`/`send_file` to a `proxy_gallery/2` helper calling the
port, forwarding the exact same path the standalone app answers
(`/gallery/index.html`, `/gallery/vendor/usd-viewer/include.js`,
`/gallery/usd/sample_billboard.usdz`), no rewrite. `GALLERY_URL`
(env, default `http://localhost:8090`) names the target;
`config/dev.exs` and `config/runtime.exs` both read it.
`WeftspunStudio.GallerySourceMock` (Mox) and
`test/router_gallery_test.exs` pin the proxy contract, following the
existing `CatalogSourceMock`/`router_test.exs` pattern exactly.

## The `usd-viewer` npm-package fix, preserved as a real patch

Diffing the old committed vendor copy against the pristine
`usd-viewer@0.0.0` npm package, file by file, found one real
divergence: `render-delegate.js`. Three fixes lived there, none
written down before this session read the minified diff directly:

1. The `./`-prefix fix RFD 0073's own `DETAILS.md` already files.
   `UsdUtils.CreateNewUsdzPackage` writes asset references as
   `./name` but stores zip entries flat; the pristine package's
   `getTexture` builds its lookup key from the raw `./name` and
   never matches. The fixed version strips the prefix first, with
   `new URL(e, "https://usd-viewer.invalid/").pathname.slice(1)`.
2. An sRGB-encoding fix: `o.encoding = R` (`sRGBEncoding`) on a
   `map`/`emissiveMap` texture, absent from the pristine package.
3. A material-side fix: `new s({side:d.side})`, preserving the flat
   quad's double-sided setting, versus the pristine `new s({})`.

`patch-package` (new devDependency) captures this as
`usd_viewer_app/patches/usd-viewer+0.0.0.patch`, generated with
`--include 'render-delegate\.js$'` to exclude the `100644`→`100755`
mode-bit noise every other vendored file picked up from this
session's own sandbox permissions. `"postinstall": "patch-package"`
re-applies it on every `npm ci`/`npm install`.

## The Rollup external-import fix, and a real Vite base-path bug

`index.html` imports usd-viewer's own bundle by its final, deployed
path, `/gallery/vendor/usd-viewer/include.js`. Running `vite build`
unmodified fails: Rollup treats it as a project module reference and
cannot resolve it on disk. `usd_viewer_app/vite.config.js` (new)
sets `build.rollupOptions.external` to a predicate matching any
`/gallery/`-prefixed id, so Rollup ships the reference as a literal
string.

A second, real bug surfaced only once Playwright drove the actual
running proxy chain, not `curl`: Vite's default `base` ("/") makes
the bundled entry script reference `/assets/index-*.js`,
root-absolute. Served under a `/gallery/` prefix, the browser
requested `http://127.0.0.1:4001/assets/index-*.js` and got a real
404, confirmed by a Playwright `response` listener logging every
4xx/5xx. `base: "/gallery/"` in `vite.config.js` fixes every asset
URL Vite itself generates. This bug could not have been caught by
`curl` against `/gallery` alone; it only shows once a browser
actually parses and requests the page's own generated script tag.

## What this session verified

- `npm ci` (clean `node_modules`) ran `postinstall`'s patch step
  automatically; `npm run build` produced a `dist/` carrying all
  three `render-delegate.js` fixes and the corrected `base`-prefixed
  asset URLs, confirmed by `grep` and by reading `dist/index.html`
  directly.
- The standalone `node server.js` (built `dist/`, port 8090)
  answered `/health`, `/gallery/index.html`,
  `/gallery/vendor/usd-viewer/include.js`, and
  `/gallery/usd/sample_billboard.usdz` directly, each `200`.
- `weftspun_studio` (`WEFTSPUN_DB=0`, no database needed for this
  path, `GALLERY_URL=http://127.0.0.1:8090`) proxied `/`, `/gallery`,
  `/gallery/vendor/usd-viewer/include.js`, and
  `/sample_billboard.usdz` through the real `HttpGallery` adapter,
  each `200`, with the COEP/COOP headers set.
- Playwright (`chromium`, real browser, not a mock) navigated the
  running proxy chain end to end. The rendered billboard's own
  texture is visible in the captured screenshot (the real dataset
  image, not a solid color or an error placeholder), confirming the
  `render-delegate.js` patch fires for real, through the whole path:
  standalone app → HTTP adapter → `Plug.Router` → browser → WASM →
  WebGL.
- `mix compile` succeeds with the new port, adapter, and router
  changes. `mix test` was not run this session (no local CockroachDB
  was available after this session masked the pre-existing
  `weftspun-crdb.service`, at the user's own request); the new
  `test/router_gallery_test.exs` was written to the exact pattern
  `test/router_test.exs` already establishes and reviewed by hand,
  but not executed.

## Open, for the next session

- SlugHorn/RFD 0074's caption labels are not part of this change.
  They live in the separate, not-yet-merged
  `weftspun/billboard-labels` repository.
- `mix test` needs a real run once a local CockroachDB is available
  again, to confirm `test/router_gallery_test.exs` actually passes
  and not only reads correctly.
- Neither `usd_viewer_app/fly.toml` nor the new Quadlet files have
  been deployed; both are written to the existing patterns
  (`character_taxonomy/fly.toml`, `weftspun-crdb.{build,container}`)
  but not run against a real Fly org or a real Podman host this
  session.
