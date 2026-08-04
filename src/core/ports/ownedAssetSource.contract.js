/**
 * The OwnedAssetSource port, as a contract test.
 *
 * Content needs one answer from a chain: which assets may this owner
 * use? A trait an owner holds is a trait a picker may offer.
 *
 * Minting and payment are not here. Those write to a chain, and a
 * headless content system never writes to a chain. See RFD 0023.
 *
 * A manifest asks the question two ways, and neither one is by
 * address. A locked collection asks "which traits of this collection
 * does the holder have?". A purchase definition asks "which traits did
 * the holder buy?". Both answer with the same shape, so both belong on
 * the same port.
 *
 * @typedef {object} Collection
 * @property {string} id
 * @property {string} name
 *
 * @typedef {object} UnlockedTraits
 * @property {string[]} ownedIDs           Trait ids the owner holds.
 * @property {Record<string, string[]>} ownedTraits  Trait ids, by group.
 *
 * @typedef {object} CollectionQuery
 * @property {string} collectionId
 * @property {string} chainName
 * @property {string} dataSource
 * @property {string|null} [wallet]  A named wallet, or null for the active one.
 *
 * @typedef {object} PurchaseQuery
 * @property {string} delegateAddress
 * @property {string} collectionName
 * @property {string|null} [wallet]
 *
 * @typedef {object} OwnedAssetSource
 * @property {() => boolean} isEnabled
 * @property {() => Promise<Collection[]>} listCollections
 * @property {(address: string) => Promise<string[]>} listOwnedTraitIds
 * @property {(query: CollectionQuery) => Promise<UnlockedTraits>} listCollectionTraits
 * @property {(query: PurchaseQuery) => Promise<UnlockedTraits>} listPurchasedTraits
 */

import { describe, it, expect } from 'vitest';

const SAMPLE_ADDRESS = '0x0000000000000000000000000000000000000001';

const SAMPLE_COLLECTION = Object.freeze({
  collectionId: 'sample-collection',
  chainName: 'ethereum',
  dataSource: 'attributes',
  wallet: SAMPLE_ADDRESS,
});

const SAMPLE_PURCHASE = Object.freeze({
  delegateAddress: SAMPLE_ADDRESS,
  collectionName: 'sample-collection',
  wallet: SAMPLE_ADDRESS,
});

/** What an adapter answers when it unlocks nothing. */
const EMPTY = { ownedIDs: [], ownedTraits: {} };

/** @param {import('./ownedAssetSource.contract.js').UnlockedTraits} unlocked */
function expectUnlockedShape(unlocked) {
  expect(Array.isArray(unlocked.ownedIDs)).toBe(true);
  for (const id of unlocked.ownedIDs) {
    expect(typeof id).toBe('string');
  }

  expect(typeof unlocked.ownedTraits).toBe('object');
  expect(unlocked.ownedTraits).not.toBeNull();
  for (const group of Object.values(unlocked.ownedTraits)) {
    expect(Array.isArray(group)).toBe(true);
  }
}

/**
 * Runs the whole OwnedAssetSource port against one adapter.
 *
 * @param {string} name
 * @param {() => OwnedAssetSource | Promise<OwnedAssetSource>} makeSource
 */
export function describeOwnedAssetSourceContract(name, makeSource) {
  describe(`OwnedAssetSource contract: ${name}`, () => {
    it('isEnabled answers with a boolean', async () => {
      const source = await makeSource();

      expect(typeof source.isEnabled()).toBe('boolean');
    });

    it('listCollections returns an array', async () => {
      const source = await makeSource();

      await expect(source.listCollections()).resolves.toBeInstanceOf(Array);
    });

    it('every collection carries a string id and name', async () => {
      const source = await makeSource();

      for (const collection of await source.listCollections()) {
        expect(typeof collection.id).toBe('string');
        expect(typeof collection.name).toBe('string');
      }
    });

    it('collection ids are unique', async () => {
      const source = await makeSource();
      const ids = (await source.listCollections()).map((c) => c.id);

      expect(new Set(ids).size).toBe(ids.length);
    });

    it('listOwnedTraitIds returns an array of strings', async () => {
      const source = await makeSource();
      const ids = await source.listOwnedTraitIds(SAMPLE_ADDRESS);

      expect(Array.isArray(ids)).toBe(true);
      for (const id of ids) {
        expect(typeof id).toBe('string');
      }
    });

    it('listOwnedTraitIds gives an empty array for no address', async () => {
      const source = await makeSource();

      await expect(source.listOwnedTraitIds('')).resolves.toEqual([]);
      await expect(source.listOwnedTraitIds(null)).resolves.toEqual([]);
      await expect(source.listOwnedTraitIds(undefined)).resolves.toEqual([]);
    });

    it('listOwnedTraitIds resolves rather than throwing for an unknown address', async () => {
      const source = await makeSource();

      await expect(
        source.listOwnedTraitIds('0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef'),
      ).resolves.toBeInstanceOf(Array);
    });

    it('a disabled source holds no assets', async () => {
      const source = await makeSource();

      if (!source.isEnabled()) {
        await expect(source.listCollections()).resolves.toEqual([]);
        await expect(source.listOwnedTraitIds(SAMPLE_ADDRESS)).resolves.toEqual([]);
        await expect(source.listCollectionTraits(SAMPLE_COLLECTION)).resolves.toEqual(EMPTY);
        await expect(source.listPurchasedTraits(SAMPLE_PURCHASE)).resolves.toEqual(EMPTY);
      }
    });

    it('listCollectionTraits answers with the unlocked shape', async () => {
      const source = await makeSource();

      expectUnlockedShape(await source.listCollectionTraits(SAMPLE_COLLECTION));
    });

    it('listPurchasedTraits answers with the unlocked shape', async () => {
      const source = await makeSource();

      expectUnlockedShape(await source.listPurchasedTraits(SAMPLE_PURCHASE));
    });

    it('an incomplete query unlocks nothing', async () => {
      // A manifest with no lock and no purchase definition must not
      // reach a wallet. The caller checks too, but the port is what
      // makes that safe for every caller.
      const source = await makeSource();

      await expect(source.listCollectionTraits({})).resolves.toEqual(EMPTY);
      await expect(source.listCollectionTraits(null)).resolves.toEqual(EMPTY);
      await expect(source.listPurchasedTraits({})).resolves.toEqual(EMPTY);
      await expect(source.listPurchasedTraits(null)).resolves.toEqual(EMPTY);
    });

    it('an unreachable chain unlocks nothing, and does not throw', async () => {
      // A picker that cannot reach a chain shows the locked set. It
      // does not fail the load, because content still serves.
      const source = await makeSource();

      await expect(
        source.listCollectionTraits({
          collectionId: 'no-such-collection',
          chainName: 'no-such-chain',
          dataSource: 'attributes',
        }),
      ).resolves.toEqual(EMPTY);
    });

    it('a caller cannot mutate the source through unlocked traits', async () => {
      const source = await makeSource();

      const first = await source.listCollectionTraits(SAMPLE_COLLECTION);
      first.ownedIDs.push('injected');
      first.ownedTraits.injected = ['injected'];

      const second = await source.listCollectionTraits(SAMPLE_COLLECTION);
      expect(second.ownedIDs).not.toContain('injected');
      expect(second.ownedTraits.injected).toBeUndefined();
    });

    it('a caller cannot mutate the source through a returned array', async () => {
      const source = await makeSource();

      const first = await source.listCollections();
      first.push({ id: 'injected', name: 'Injected' });

      const second = await source.listCollections();
      expect(second.map((c) => c.id)).not.toContain('injected');
    });
  });
}
