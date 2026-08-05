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
