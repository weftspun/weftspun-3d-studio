# RFD 0015: Phygital passport

**State:** abandoned
**Feature:** phygital passport

## Decision

This design is abandoned. The project does not do NFTs. The phygital
passport route is not part of the shipped feature set.

The mock route and the NFC roadmap stay out of scope. Remove related
references from the codebase as part of the strip task.

## Status of the strip

The strip is complete for this feature. The repository no longer
holds the passport code or the passport documents.

Removed files:

- `src/pages/PhygitalVerify.jsx` and its style module
- `src/library/phygital/` with the client, the schema, and the mock
- `docs/PHYGITAL_PASSPORT_API.md`
- `docs/PHYGITAL_NFC_APPAREL_ROADMAP.md`

The README no longer names the `/verify/:serialId` route. No route
existed for that path, so the README made a false claim.

## References

- Strip task: issue #2 (Strip blockchain features)

## Related

RFD 0012 is also abandoned. The project does not pursue NFT-linked
assets.
