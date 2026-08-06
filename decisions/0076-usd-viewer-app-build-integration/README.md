# RFD 0076: usd_viewer_app, its own app, reached through a port

**State:** prediscussion
**Scope:** `usd_viewer_app/`, `lib/weftspun_studio/ports/gallery_source.ex`,
`lib/weftspun_studio/adapters/http_gallery.ex`, `lib/weftspun_studio/router.ex`,
`deploy/quadlet/`, `Dockerfile`, `Dockerfile.fly`

## Problem

`priv/static/gallery/`, what `router.ex` served at `/gallery`, was a
hand-copied snapshot of `usd_viewer_app/`, kept in sync by no
script. No Dockerfile ran `npm`, and the copy carried a real,
unrecorded fix to the `usd-viewer` npm package. `usd_viewer_app`
itself had no deploy of its own.

## Decision

`usd_viewer_app` becomes its own deployed app, the separation
`character_taxonomy/` already has: its own `Dockerfile`, `fly.toml`,
and Quadlet pair, served by `server.js`, a small static server.

`weftspun_studio` stops holding the gallery's bytes on disk. RFD
0022/0023's ports-and-adapters split gives the shape:
`WeftspunStudio.Ports.GallerySource` (one `fetch/2`), and
`WeftspunStudio.Adapters.HttpGallery`, a plain reverse-proxy
adapter, the shape `Adapters.ReplicateJobs` already has.
`router.ex`'s gallery routes forward through the port at an
unchanged path; `GALLERY_URL` (env) names the deployed app.

The `usd-viewer` fix stays as a `patch-package` patch, applied by
`npm ci`'s own `postinstall`. See `DETAILS.md` for the fix, a Vite
base-path bug Playwright caught live, and what verified end to end.

## Related

RFD 0073 gives the gallery this serves, and files the `usd-viewer`
bug the patch fixes. RFD 0022/0023 give the ports-and-adapters
split. RFD 0062 gives the Fly.io toplevel and RFD 0058 the Podman
Quadlet path; `character_taxonomy` gives the separate-app pattern
mirrored here.
