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

    async listCollectionTraits(query) {
      const { collectionId, chainName, dataSource, wallet = null } = query ?? {};
      if (!collectionId || !chainName || !dataSource) return empty();

      try {
        const owned = await (
          await getWallet()
        ).getTraitsFromCollection(collectionId, chainName, dataSource, wallet);
        return normaliseUnlocked(owned);
      } catch {
        return empty();
      }
    },

    async listPurchasedTraits(query) {
      const { delegateAddress = null, collectionName, wallet = null } = query ?? {};
      // The collection name is what the read needs. A delegate address
      // is optional, and most manifests carry none.
      if (!collectionName) return empty();

      try {
        const owned = await (
          await getWallet()
        ).getSolanaPurchasedAssets({ delegateAddress, collectionName }, wallet);
        return normaliseUnlocked(owned);
      } catch {
        return empty();
      }
    },
  };
}

/** What the adapter answers when it unlocks nothing. */
function empty() {
  return { ownedIDs: [], ownedTraits: {} };
}

/**
 * The wallet layer answers with an OwnedNFTTraitIDs, with a plain
 * object, or with null when the read failed. The port answers with one
 * shape, so this makes one.
 *
 * The copy is not a nicety. The wallet layer holds its answer, and a
 * caller that writes to the returned arrays would reach the next
 * caller through it.
 */
function normaliseUnlocked(owned) {
  if (!owned) return empty();

  const ownedIDs = Array.isArray(owned.ownedIDs)
    ? owned.ownedIDs.filter((id) => typeof id === 'string')
    : [];

  const ownedTraits = {};
  for (const [group, ids] of Object.entries(owned.ownedTraits ?? {})) {
    if (Array.isArray(ids)) {
      ownedTraits[group] = ids.filter((id) => typeof id === 'string');
    }
  }

  return { ownedIDs, ownedTraits };
}

/** Accepts the several shapes the wallet layer returns. */
function normalise(owned) {
  if (!owned) return [];
  if (Array.isArray(owned)) return owned.filter((id) => typeof id === 'string');
  if (typeof owned.ownTraits === 'function' && !owned.ownTraits()) return [];

  const ids = owned.ownedIDs ?? owned.ids ?? [];
  return Array.isArray(ids) ? ids.filter((id) => typeof id === 'string') : [];
}
