# RFD Index

This directory holds Request-for-Discussion documents. It follows the
Oxide RFD style.

Each RFD is a reference design. It records a decision and points to
the canonical documentation. It does not restate the documentation.
See the STE policy below for the writing rules.

## Index

| RFD | Reference design | State |
|-----|------------------|-------|
| 0000 | Conventions (RFD style, STE, DRY) | published |
| 0001 | App shell and routing | published |
| 0002 | Studio pipeline graph | published |
| 0003 | Task Manager job lifecycle | published |
| 0004 | AIGC task catalog | published |
| 0005 | Avatar and VRM pipeline | published |
| 0006 | Layer decomposition (See-Through) | discussion |
| 0007 | Motion validation (Kimodo) | discussion |
| 0008 | Appearance trait extraction and remix | discussion |
| 0009 | Viewport and scene rendering | published |
| 0010 | WebXR and IWSDK lab | published |
| 0011 | Spatial fabric publish | published |
| 0012 | Wallet, minting, and x402 | abandoned |
| 0013 | Public demo deploy | published |
| 0014 | Batch processing | published |
| 0015 | Phygital passport | abandoned |

## DRY policy

The repository keeps one source of truth for each design.

- The README describes the feature surface.
- The docs/ tree holds the detailed designs and roadmaps.
- The src/ tree implements the behavior.
- This directory records the durable decisions only.

An RFD points to the source. It does not copy the source.
An RFD that restates a document will drift. It must instead link the
document. When a design changes, update the source first. Then update
the RFD to point at the new source.

## STE policy

Each RFD uses ASD-STE100 Simplified Technical English. The rules:

- One sentence per instruction.
- Keep sentences under 25 words.
- Use active voice.
- Do not use marketing adjectives.
- Do not use phrasal verbs.
- Do not use semicolons or em dashes in prose.
- Name one thing by one name.

The repository enforces this with a linter:

```bash
npm run lint:ste
```

The linter fails when any file scores above 2.5 violations per 100
words. Add the npm script to CI before merge.
