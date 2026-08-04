# RFD 0013: Public demo deploy

**State:** published
**Feature:** public demo

## Problem

The app runs against a private DGX backend. A public deploy must
not expose LAN or DGX secrets. A demo must still show the viewport,
VRM upload, and traits.

## Decision

Deploy a public viewport demo on Vercel. The build sets
VITE_PUBLIC_DEMO=1 and loads loot assets through a CDN.

The verify:public-env script blocks client secrets in CI and on
Vercel. Full AI generation stays on local dev and the self-hosted
backend. The demo does not require VITE_API_ENDPOINT.

## References

- Config: `vercel.json`
- Guard: `scripts/verify-public-build-env.mjs`
- Docs: `docs/PUBLIC_DEPLOY.md`
- UI toggle: `src/library/runtimeUi.js`

## Related

RFD 0001 defines the app shell that the demo deploys.
