/**
 * CharacterManifestData asks the OwnedAssetSource port, and nothing
 * else, for which assets the owner may use.
 *
 * These tests are the reason the module could leave the chain leak
 * list. See RFD 0023.
 */
import { describe, it, expect, vi } from 'vitest';

// CharacterManifestData takes one pure helper from ./utils, and that
// module pulls the VRM and three.js exporters at load time. RFD 0023
// records the same cost for the wallet adapter. Only getAsArray is
// needed here.
vi.mock('./utils', () => ({
  getAsArray: (target) => (target == null ? [] : Array.isArray(target) ? target : [target]),
}));

import { CharacterManifestData } from './CharacterManifestData.js';

/** A manifest with one model group of two locked traits. */
function manifest(extra = {}) {
  return {
    assetsLocation: '',
    traitsDirectory: '',
    thumbnailsDirectory: '',
    traits: [
      {
        name: 'Head',
        trait: 'HEAD',
        collection: [
          { id: 'head_1', name: 'Head One', directory: 'a.glb', locked: true },
          { id: 'head_2', name: 'Head Two', directory: 'b.glb', locked: true },
        ],
      },
    ],
    ...extra,
  };
}

function stubSource(unlocked) {
  return {
    isEnabled: () => true,
    listCollections: vi.fn(async () => []),
    listOwnedTraitIds: vi.fn(async () => []),
    listCollectionTraits: vi.fn(async () => unlocked),
    listPurchasedTraits: vi.fn(async () => unlocked),
  };
}

const NOTHING = { ownedIDs: [], ownedTraits: {} };

describe('CharacterManifestData and the OwnedAssetSource port', () => {
  it('takes the null adapter when no source is given', async () => {
    // Content code that reaches no chain is the default, not a setting.
    const data = new CharacterManifestData(manifest(), 'test');
    const source = await data.ownedAssetSource;

    expect(source.isEnabled()).toBe(false);
    await expect(source.listCollectionTraits({})).resolves.toEqual(NOTHING);
  });

  it('asks the port for a locked collection, with the manifest values', async () => {
    const source = stubSource(NOTHING);
    const data = new CharacterManifestData(
      manifest({ collectionLockID: 'anata', chainName: 'ethereum', dataSource: 'attributes' }),
      'test',
      source,
    );

    await data.unlockNFTAssetsWithWallet('0xabc');

    expect(source.listCollectionTraits).toHaveBeenCalledWith({
      collectionId: 'anata',
      chainName: 'ethereum',
      dataSource: 'attributes',
      wallet: '0xabc',
    });
  });

  it('unlocks the traits the port reports', async () => {
    const source = stubSource({ ownedIDs: ['head_1'], ownedTraits: {} });
    const data = new CharacterManifestData(
      manifest({ collectionLockID: 'anata', chainName: 'ethereum', dataSource: 'attributes' }),
      'test',
      source,
    );

    await data.unlockNFTAssetsWithWallet();

    // getAllTraitOptions hides what is still locked, so this is what a
    // picker would offer.
    expect(data.getAllTraitOptions().map((o) => o.id)).toEqual(['head_1']);
  });

  it('does not ask the port when the manifest has no lock', async () => {
    const source = stubSource(NOTHING);
    const data = new CharacterManifestData(manifest(), 'test', source);

    await data.unlockNFTAssetsWithWallet();

    expect(source.listCollectionTraits).not.toHaveBeenCalled();
  });

  it('asks the port for purchased traits, with the purchase definition', async () => {
    const source = stubSource(NOTHING);
    const data = new CharacterManifestData(
      manifest({
        solanaPurchaseAssets: {
          merkleTreeAddress: '0xtree',
          depositAddress: '0xdeposit',
          collectionName: 'anata',
          delegateAddress: '0xdelegate',
        },
      }),
      'test',
      source,
    );

    await data.unlockPurchasedAssetsWithWallet('0xabc');

    expect(source.listPurchasedTraits).toHaveBeenCalledWith({
      delegateAddress: '0xdelegate',
      collectionName: 'anata',
      wallet: '0xabc',
    });
  });

  it('accepts a source that arrives as a promise', async () => {
    // The composition root builds the wallet adapter through a dynamic
    // import, so what reaches the constructor is a promise.
    const source = stubSource({ ownedIDs: ['head_1'], ownedTraits: {} });
    const data = new CharacterManifestData(
      manifest({ collectionLockID: 'anata', chainName: 'ethereum', dataSource: 'attributes' }),
      'test',
      Promise.resolve(source),
    );

    await data.unlockNFTAssetsWithWallet();

    expect(source.listCollectionTraits).toHaveBeenCalled();
  });

  it('a locked manifest with the null adapter unlocks nothing, and does not throw', async () => {
    const data = new CharacterManifestData(
      manifest({ collectionLockID: 'anata', chainName: 'ethereum', dataSource: 'attributes' }),
      'test',
    );

    await expect(data.unlockWalletOwnedTraits()).resolves.toBeUndefined();
    expect(data.getAllTraitOptions()).toEqual([]);
  });
});
