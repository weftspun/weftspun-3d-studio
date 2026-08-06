/**
 * Driven adapter: no chain at all.
 *
 * This is the headless case, and the default. A content deployment
 * serves content with no wallet, no network, and no chain library.
 *
 * The whole point is what this file does not import. It reaches no
 * chain library and no module in `src/chain/`, so a build that takes
 * this adapter carries none of that code.
 *
 * Satisfies the OwnedAssetSource port. See RFD 0023.
 */

/**
 * @returns {import('../ports/ownedAssetSource.contract.js').OwnedAssetSource}
 */
export function makeNullOwnedAssetSource() {
  return {
    isEnabled() {
      return false;
    },

    async listCollections() {
      return [];
    },

    async listOwnedTraitIds() {
      return [];
    },

    // A fresh object each call. A caller that keeps the answer, and
    // then writes to it, must not reach the next caller.
    async listCollectionTraits() {
      return { ownedIDs: [], ownedTraits: {} };
    },

    async listPurchasedTraits() {
      return { ownedIDs: [], ownedTraits: {} };
    },
  };
}
