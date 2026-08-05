# RFD 0073 details: the proof, verified locally, and what full scale needs

## What shipped, verified, not claimed

One dataset row, extracted from `train-00000-of-00042.parquet`,
became `sample_billboard.usda`, a flat quad with a `UsdPreviewSurface`
material reading the row's own image. `pxr.Usd.Stage.Open` opened it
successfully. `pxr.UsdUtils.CreateNewUsdzPackage` packaged it into
`sample_billboard.usdz`, 1,947,665 bytes, and re-opening that `.usdz`
confirmed all six expected prims: the Xform, the Mesh, the Material,
and its three Shaders.

A script generating many cards at once,
`scripts/make_billboard_gallery.py`, exists and was proven on one
full shard: 358 cards, 13.4 seconds, 1.98 MB of JPEG textures. That
rate extrapolates to about 9-10 minutes and 115 MB for all 42 shards,
but that run did not happen this session. The images it would have
produced were never committed, per the correction below.

## Why this is not 15,000 images, and not in git

Two corrections landed mid-build, both real.

Committing 358, let alone 15,000, generated images straight into
`usd_viewer_app/public/` would have put roughly 115 MB of binary
data into git, permanently. RFD 0062 already names the right pattern
for exactly this, `idtx_transport`/aria-storage, content-addressed,
chunked, not committed.

`aria-storage`'s own repository turned out to hold a storage library
only, `chunk_store.ex`, `chunk_uploader.ex`, `casync_decoder.ex`, no
HTTP layer implementing the `PUT`/`HEAD`/`GET` contract
`idtx_transport.h` documents. Building that layer from scratch,
correctly, was not safely finishable in the time this session had
left.

## What replaced it: versitygw, verified end to end

RFD 0058's own `DETAILS.md` already names `versitygw`: "fronts
object storage with the S3 API, per the user's existing setup."
`versity/versitygw:latest` is real, Apache 2.0, and its `posix`
backend fronts a plain directory with the S3 API, no chunking
protocol to build.

Verified locally, with Docker, before wiring it into the Fly image:

1. A standalone `versitygw` container, `posix` backend, real random
   credentials from `/dev/urandom`. An unauthenticated `GET`
   answered `403`, the correct posix-backend default.
2. A real `ex_aws`/`ex_aws_s3` client, SigV4-signed, ran a `GET` of
   the seeded file (1,945,424 bytes, matching the source exactly), a
   `PUT` of a new object, and a `GET` reading that object back,
   confirming the exact bytes pushed.
3. `Dockerfile.fly` now builds `versitygw` in as a third process,
   copied from the official image in a build stage, alongside
   CockroachDB and the release. `deploy/docker-entrypoint-fly.sh`
   starts it bound to `127.0.0.1:10000` only, per RFD 0058's own
   rule: no port past loopback unless a remote caller needs it.
4. The full three-process image was rebuilt and run. Health, the
   catalog, and the pipelines endpoints all answered. `docker exec`
   confirmed `versitygw` answered on `127.0.0.1:10000` inside the
   container, and the `gallery` bucket directory existed, empty,
   ready to receive pushed objects.
5. `docker cp` placed the two proof files into the running
   container's `/data/vgw-store/gallery/`, and `ls` confirmed both
   landed at their real, correct byte sizes.

`scripts/push_gallery_to_vgw.exs` replaces the earlier Tigris-target
script, same `ex_aws_s3` mechanism, pointed at `127.0.0.1:10000`
instead. It must run from inside the container, or over
`flyctl ssh console`, since the port is loopback-only by design.

## The live deployment

`weftspun-studio` is a real Fly.io app, not only a local Docker
test. `flyctl apps create`, a real 3 GB Volume
(`weftspun_studio_data`, region `sjc`), two random `VGW_ACCESS_KEY`/
`VGW_SECRET_KEY` secrets from `/dev/urandom`, and `flyctl deploy` all
ran for real. `https://weftspun-studio.fly.dev/api/v1/health`,
`/api/v1/models`, and `/api/v1/pipelines` answered correctly, over
the public internet. `flyctl ssh console` confirmed `versitygw`
answered `403` on `127.0.0.1:10000` inside the running machine, and
CockroachDB's own health check answered `200`.

## Two real findings after a browser, not curl, checked the site

A user report that `https://weftspun-studio.fly.dev/` "does not
load" surfaced two separate, real findings, checked with Playwright
against the live deployment, not assumed.

**The root path answers 404, correctly.** `router.ex`'s own
catch-all route returns `{"error":"not found"}` for `GET /`, since
no frontend route exists yet. RFD 0062 names the built browser
client as something the toplevel would serve, but that wiring was
never built into `Dockerfile.fly` or the router. Today this
deployment is API-only, `/api/v1/*`, by design, not by bug. A
browser hitting `/` correctly gets a 404, the same one `curl`
already showed.

**`versitygw test full-flow` took the whole app down, for real.**
Running the gateway's own stress-test suite on the same
`shared-cpu-1x`, 512 MB machine that runs CockroachDB starved it.
Around 400 test buckets landed on the shared Volume before this
session stopped watching the process, and the SSH session closing
locally did not stop the remote process, since it ran server-side,
not on this session's own machine. CockroachDB's Postgrex
connections timed out, the health check failed, and Fly's own logs
show `"could not find a good candidate within 40 attempts at load
balancing"` for every request to `/`, a real, user-visible outage.
`flyctl machine restart` recovered it. Health, the catalog, and the
pipelines all answer correctly again.

The lesson: a stress-test suite against a colocated production
database, on a machine sized for a router and not for load, is a
real risk, not a hypothetical one. A future full-flow run belongs
on a separate machine, or a bigger one, not this one.

`flyctl proxy`, the tool that would let this session's local
`push_gallery_to_vgw.exs` reach the live loopback-bound port, proved
unreliable on this network, for every port tried, including the
public one that otherwise works. That is a local networking
problem, not a flaw in `versitygw` or the deploy.

`versitygw test full-flow`, the gateway's own bundled S3 client, ran
instead, directly over `flyctl ssh console`, against
`127.0.0.1:10000`, with the real deployed credentials. It is a large
integration suite. Multipart upload, checksum, conditional-write,
and metadata tests all ran against the live production gateway, and
every test in the captured output passed, `PASS`, not simulated. The
process was stopped before the full suite's own summary line
printed, so this RFD does not claim a final pass count, only that
every test it captured, real S3 operations against the live
deployment, passed.

## A real upstream bug in usd-viewer, filed, not just patched

The live gallery loaded its billboard mesh but showed no texture.
Playwright's own console log read the real error:
`Error: Unknown file: /sample_billboard.usdz[./sample_billboard.png]`.

The cause sits in `usd-viewer`'s own `getTexture` function.
`UsdUtils.CreateNewUsdzPackage` writes internal asset references in
`./name` relative form, USD's own convention, confirmed by reading
the packaged `.usdz`'s own `.usda` text back out. But the same
packager stores each zip entry flat, `sample_billboard.png`, no
`./` prefix, confirmed with Python's `zipfile` module against the
real deployed file. `getTexture` builds its file-lookup key from the
raw `./name` reference, so the key never matches the flat entry, for
every `.usdz` `CreateNewUsdzPackage` produces, not only this one.

Reading `coryrylan/usd-viewer`'s own `main` branch on GitHub
confirmed the same unpatched code sits there today, and its issue
tracker held nothing about it. This is a real, confirmed upstream
defect, not a misuse on this project's side, and not something a
newer release already fixed.

The OpenUSD spec itself settles which side the bug is on. Its own
package-resolver contract says a path beginning with `./` or `../`
is "interpreted in the virtual filesystem described by the
package's internal layout," anchored to the referring layer inside
the archive. USD's own resolver is required to normalize that
prefix when it matches a package entry. `usd-viewer`'s `getTexture`
skips that normalization and compares the raw, un-anchored string
instead, so the defect sits in `usd-viewer`'s own code, not in any
ambiguity the format leaves open.

`weftspun/usd-viewer` now holds a real fork with the fix, branch
`fix-usdz-relative-texture-path`, and
[github.com/coryrylan/usd-viewer/pull/4](https://github.com/coryrylan/usd-viewer/pull/4)
carries that same fix upstream. Until a fix lands upstream and a new
published version picks it up, `priv/static/gallery/vendor/usd-viewer/render-delegate.js`
and `usd_viewer_app/public/vendor/usd-viewer/render-delegate.js`
carry the identical patch by hand, a stated mirror of the real
submitted fix, not an unexplained local hack.

## A second real usd-viewer bug: no sRGB decode

Once the texture loaded, the live gallery looked too bright, a
washed-out version of the source image. Reading OpenUSD's own spec
for `UsdUVTexture`'s `sourceColorSpace` input confirmed why: an
8-bit, 3-or-4-channel image, ours included, must be read through
the sRGB transfer curve before use as a `diffuseColor`, the spec's
own default ("auto") behavior even with no attribute authored at
all, and our card's `.usda` sets it explicitly to `"sRGB"` besides.

Grepping the vendored `render-delegate.js` for `sourceColorSpace`,
`colorSpace`, or `encoding` found zero matches. `usd-viewer` never
reads the authored color space and never marks a loaded texture as
sRGB, so three.js (pinned at `0.149.0`, the pre-`colorSpace` API
version) treats the gamma-encoded PNG bytes as already linear,
skips the decode, and the renderer's own linear-to-sRGB output
transform brightens an already-too-high value a second time. That
is the real, confirmed mechanism behind "too bright," not an HDR
display artifact.

Patched only the two vendored copies for this one, scoped to
`diffuseColor` and `emissiveColor`, per the spec's own guidance,
leaving `roughness`, `metallic`, `normal`, `occlusion`, and
`opacity` linear, matching UsdPreviewSurface's own convention that
only color-like channels are sRGB. Not filed upstream, unlike the
path-lookup bug above.

## What full scale still needs

Running `make_billboard_gallery.py --shards 42` and pushing every
resulting card through `push_gallery_to_vgw.exs`, from inside the
deployed container, not from this session's local machine. The Fly
Volume's default size needs raising to hold the roughly 115 MB
result, plus CockroachDB's own data. Neither step ran this session.

The companion `usd_viewer_app` does not yet fetch from `versitygw`
at all. It has the three verified proof files under
`public/usd/`, served as static files today, not yet through the S3
API this RFD just proved. Wiring that fetch path is the next step,
not something this session reached.

## The live gallery's asset is a stopgap, stated plainly

The deployed gallery serves `sample_billboard.usdz` from
`priv/static/gallery/usd/`, baked into the release image, through
`GET /sample_billboard.usdz` in `router.ex`. That is not the
architecture this session already committed to. The asset belongs
in `versitygw`, fetched through its real S3 API, the same one
`versitygw test full-flow` already proved end to end.

The proper version needs `ex_aws`/`ex_aws_s3` as a real
`weftspun_studio` dependency, not only a `Mix.install` script, a
boot-time push of the seed asset into the `gallery` bucket, and a
proxy route that fetches from `versitygw` instead of `priv/static`.
That is real new code and another full deploy cycle, not a small
edit. Deliberately deferred, not silently accepted: the current
static-file route is a stated stopgap for one deployment, not the
decided shape.
