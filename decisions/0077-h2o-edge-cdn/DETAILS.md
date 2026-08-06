# RFD 0077 details: RED, GREEN, REFACTOR

This RFD verifies the plan before writing any code for it, the same
discipline a test suite gives a function: state the claim, check it
against something real, and only then decide what to build.

## RED: the naive plan fails on inspection, no code needed to show it

The claim on the table: "stand up `h2o-bench-tpcc` (or H2O) in
multiple Fly regions as a CDN, fixes the no-caching gap in RFD
0076's proxy chain."

Two checks, both against real sources, both fail the claim before
any container gets built:

1. **`h2o-bench-tpcc` is not a reverse proxy.** Its own README states
   what it is: a TPC-C benchmark harness, `libh2o`'s event loop with
   `libfdb_c` calls compiled directly into the worker pool, built to
   measure FoundationDB write throughput. It has no static-file
   serving, no reverse-proxy config, no caching logic. It cannot
   front `weftspun_studio` or `usd_viewer_app` as written.
2. **H2O itself has no response cache.** Checked against H2O's own
   configuration reference (`configure/proxy_directives.html`): the
   proxy module's only buffer-related directive,
   `proxy.max-buffer-size`, is explicitly transitory — it decouples
   the upstream and downstream connections and then discards the
   data. No directive stores a response body for reuse. This is a
   real, structural difference from nginx's `proxy_cache` or
   Varnish, both of which do store and serve cached bytes.

The consequence: even a real, multi-region H2O deployment gives
closer HTTP/3/QUIC connection termination, and nothing else. Every
request still crosses to the single origin (`weftspun_studio`, Fly
region `sjc`) for the actual bytes, on every request, from every
edge region. The slow hop RFD 0076's gap actually names, a repeated
full fetch of multi-megabyte WASM binaries with no cache anywhere,
is not fixed by this plan. A user in `syd` gets a faster TLS
handshake and a slower-than-necessary origin fetch behind it, not a
cached response.

This is the RED step: the test the plan needed to pass, "does this
avoid re-fetching from origin," fails, verified by reading the two
projects' own documentation, not by building and then discovering it
at runtime.

## GREEN: the smallest change that actually passes

`Cache-Control`, at the existing origin, no new service:

- `usd_viewer_app/server.js` sets `Cache-Control: public,
  max-age=31536000, immutable` on every path under `dist/assets/`
  (Vite's own content-hashed filenames, such as
  `index-797Eygc6.js` — the hash changes only when the content
  does, so an immutable, year-long cache is correct, not stale) and
  a short `Cache-Control: public, max-age=300` on `index.html` and
  every other path, so a caption or dataset-card update still
  reaches a browser in minutes, not a year.
- `weftspun_studio`'s `HttpGallery.fetch` and `Router.proxy_gallery`
  forward whatever `Cache-Control` the gallery app sent, instead of
  the current behavior of setting only `content-type` and the
  COEP/COOP pair.

This needs no new deployed app, no new language in the fleet, no
multi-region cost, and it is real: a browser that already fetched
`emHdBindings.wasm` once does not fetch it again, for free, using
infrastructure every browser already has. RFD 0058 and RFD 0067 both
already found no load that needs more than this — a browser cache
plus a content-hashed filename is the whole fix at today's traffic.

Not yet built: this RFD stops at the plan, per the user's own
instruction to write the RFD and stop, not ship the GREEN step's
code in the same pass.

## REFACTOR: Tigris, not H2O, if load ever justifies more than GREEN

If traffic ever outgrows a browser cache (many first-time visitors,
not repeat ones, is the case a browser cache cannot help), the right
next step is not H2O. It is **Tigris**, Fly's own S3-compatible
object storage.

Checked against Fly's own docs: Tigris replicates an object close to
the region where it was written, then close to the region that
requests it, automatically, with no separate proxy and no config.
Fly's own claim: "This automatic global replication can replace a
CDN." That is precisely the capability H2O's RED step found missing
— H2O has no directive that stores a response body for reuse; Tigris
stores the bytes themselves, at the edge, as its whole job.

The concrete move: push the gallery's static assets (the WASM
binaries, the `usd-viewer` vendor JS, the dataset images and
`.usdz` files) to Tigris directly, and reference them by their
Tigris URL. `versitygw`, RFD 0073's self-hosted S3-API gateway on a
single-region Fly Volume, is a manual stand-in for exactly what
Tigris already does natively; Tigris replaces it, not adds to it.
`weftspun_studio` and `usd_viewer_app` still need one live app
origin for the dynamic parts (the API, the current `index.html`
shell), but the static bytes stop being this app's problem.

This is still a real decision, not a code change to make in this
pass: it retires `versitygw` and the Fly Volume it depends on, and
needs its own RFD once a load number justifies it — the same
reasoning RFD 0067 already applied to FoundationDB.
