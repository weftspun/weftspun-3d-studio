# RFD 0012: Wallet, minting, and x402

**State:** abandoned
**Feature:** wallet and minting

## Decision

This design is abandoned. The project does not do NFTs. The app
does not integrate a wallet, mint files, or use x402 micropayments.

The blockchain integration stays out of the shipped feature set.
Remove remaining blockchain references from the codebase as part of
the strip task.

## References

- Strip task: issue #2 (Strip blockchain features)
- Current references: `src/library/mint-utils.js`
- Current references: `src/library/baseX402Manager.js`

## Related

RFD 0005 defines the avatar and VRM assets. This RFD does not apply.
