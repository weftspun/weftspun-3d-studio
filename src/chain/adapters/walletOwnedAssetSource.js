/**
 * Driven adapter: owned assets, read from a wallet.
 *
 * This file sits in `src/chain/` and not in `src/core/`, because it
 * reaches chain code. An adapter belongs on the outside of the
 * hexagon, and the core reaches it only through the port.
 *
 * Satisfies the OwnedAssetSource port. See RFD 0023.
 */
/**
 * @param {object} [options]
 * @param {object[]} [options.collections]  Collection definitions the client knows.
 * @param {object} [options.walletCollections] Injected for tests.
 * @returns {import('../../core/ports/ownedAssetSource.contract.js').OwnedAssetSource}
 */
export function makeWalletOwnedAssetSource(options = {}) {
  const collections = Object.freeze(
    (options.collections ?? []).map((c) => Object.freeze({ ...c })),
  );

  // The wallet stack loads lazily, through a dynamic import.
  //
  // A static import would pull WalletCollections, and through it the
  // VRM and three.js exporters, into every consumer of this module.
  // Those modules run work at load time. A caller that injects a
  // stub then pays for a stack it never uses, which is the cost the
  // port exists to remove.
  let wallet = options.walletCollections ?? null;
  const getWallet = async () => {
    if (!wallet) {
      const { WalletCollections } = await import('../walletCollections');
      wallet = new WalletCollections();
    }
    return wallet;
  };

  return {
    isEnabled() {
      return true;
    },

    async listCollections() {
      return collections.map((c) => ({ ...c }));
    },

    async listOwnedTraitIds(address) {
      if (!address) return [];

      // A wallet read reaches the network, and a network read fails.
      // A picker that cannot reach a chain shows no owned traits,
      // which is the same answer the null adapter gives.
      try {
        const owned = await (await getWallet()).getOwnedTraitIDs(address);
        return normalise(owned);
      } catch {
        return [];
      }
    },
  };
}

/** Accepts the several shapes the wallet layer returns. */
function normalise(owned) {
  if (!owned) return [];
  if (Array.isArray(owned)) return owned.filter((id) => typeof id === 'string');
  if (typeof owned.ownTraits === 'function' && !owned.ownTraits()) return [];

  const ids = owned.ownedIDs ?? owned.ids ?? [];
  return Array.isArray(ids) ? ids.filter((id) => typeof id === 'string') : [];
}
