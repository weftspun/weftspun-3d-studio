/**
 * The OwnedAssetSource port, as a contract test.
 *
 * Content needs one answer from a chain: which assets may this owner
 * use? A trait an owner holds is a trait a picker may offer.
 *
 * Minting and payment are not here. Those write to a chain, and a
 * headless content system never writes to a chain. See RFD 0023.
 *
 * @typedef {object} Collection
 * @property {string} id
 * @property {string} name
 *
 * @typedef {object} OwnedAssetSource
 * @property {() => boolean} isEnabled
 * @property {() => Promise<Collection[]>} listCollections
 * @property {(address: string) => Promise<string[]>} listOwnedTraitIds
 */

import { describe, it, expect } from 'vitest';

const SAMPLE_ADDRESS = '0x0000000000000000000000000000000000000001';

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
      }
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
