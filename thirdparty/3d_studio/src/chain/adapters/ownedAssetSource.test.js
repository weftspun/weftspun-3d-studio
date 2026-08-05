/**
 * Both OwnedAssetSource adapters run the same port contract.
 * See RFD 0023.
 */
import { describe, it, expect, vi } from 'vitest';

import { describeOwnedAssetSourceContract } from '../../core/ports/ownedAssetSource.contract.js';
import { makeNullOwnedAssetSource } from '../../core/adapters/nullOwnedAssetSource.js';
import { makeWalletOwnedAssetSource } from './walletOwnedAssetSource.js';

const COLLECTIONS = [
  { id: 'anata', name: 'Anata' },
  { id: 'on1', name: '0N1 Force' },
];

/**
 * Stands in for WalletCollections.
 *
 * It holds one answer and hands the same object back every call, the
 * way the real layer does. That is what makes the contract's mutation
 * test mean something: a leak through the returned arrays would show.
 */
function stubWallet(owned, unlocked = { ownedIDs: [], ownedTraits: {} }) {
  return {
    getOwnedTraitIDs: vi.fn(async () => owned),
    getTraitsFromCollection: vi.fn(async (collectionId) =>
      collectionId === 'sample-collection' ? unlocked : null,
    ),
    getSolanaPurchasedAssets: vi.fn(async () => unlocked),
  };
}

describeOwnedAssetSourceContract('null', () => makeNullOwnedAssetSource());

describeOwnedAssetSourceContract('wallet', () =>
  makeWalletOwnedAssetSource({
    collections: COLLECTIONS,
    walletCollections: stubWallet(['trait_a', 'trait_b'], {
      ownedIDs: ['trait_a'],
      ownedTraits: { Head: ['head_1'] },
    }),
  }),
);

describe('nullOwnedAssetSource', () => {
  it('reports itself disabled', () => {
    expect(makeNullOwnedAssetSource().isEnabled()).toBe(false);
  });

  it('holds nothing for any address', async () => {
    const source = makeNullOwnedAssetSource();

    await expect(source.listOwnedTraitIds('0xabc')).resolves.toEqual([]);
  });
});

describe('walletOwnedAssetSource', () => {
  it('reports itself enabled', () => {
    expect(makeWalletOwnedAssetSource({ walletCollections: stubWallet([]) }).isEnabled()).toBe(
      true,
    );
  });

  it('returns the trait ids the wallet holds', async () => {
    const source = makeWalletOwnedAssetSource({
      collections: COLLECTIONS,
      walletCollections: stubWallet(['trait_a']),
    });

    await expect(source.listOwnedTraitIds('0xabc')).resolves.toEqual(['trait_a']);
  });

  it('reads the ownedIDs shape the wallet layer returns', async () => {
    const source = makeWalletOwnedAssetSource({
      walletCollections: stubWallet({ ownedIDs: ['trait_c'], ownTraits: () => true }),
    });

    await expect(source.listOwnedTraitIds('0xabc')).resolves.toEqual(['trait_c']);
  });

  it('gives an empty list when the wallet read fails', async () => {
    const failing = {
      getOwnedTraitIDs: vi.fn(async () => {
        throw new Error('network down');
      }),
    };
    const source = makeWalletOwnedAssetSource({ walletCollections: failing });

    // A picker that cannot reach a chain shows no owned traits. It
    // does not break the page.
    await expect(source.listOwnedTraitIds('0xabc')).resolves.toEqual([]);
  });

  it('does not read the wallet for an empty address', async () => {
    const wallet = stubWallet(['trait_a']);
    const source = makeWalletOwnedAssetSource({ walletCollections: wallet });

    await source.listOwnedTraitIds('');

    expect(wallet.getOwnedTraitIDs).not.toHaveBeenCalled();
  });

  it('reads a locked collection with the arguments the manifest gave', async () => {
    const wallet = stubWallet([], { ownedIDs: ['head_1'], ownedTraits: { Head: ['head_1'] } });
    const source = makeWalletOwnedAssetSource({ walletCollections: wallet });

    const unlocked = await source.listCollectionTraits({
      collectionId: 'sample-collection',
      chainName: 'ethereum',
      dataSource: 'attributes',
      wallet: '0xabc',
    });

    expect(wallet.getTraitsFromCollection).toHaveBeenCalledWith(
      'sample-collection',
      'ethereum',
      'attributes',
      '0xabc',
    );
    expect(unlocked).toEqual({ ownedIDs: ['head_1'], ownedTraits: { Head: ['head_1'] } });
  });

  it('does not read the wallet when the manifest names no collection', async () => {
    const wallet = stubWallet([]);
    const source = makeWalletOwnedAssetSource({ walletCollections: wallet });

    await source.listCollectionTraits({ chainName: 'ethereum', dataSource: 'attributes' });

    expect(wallet.getTraitsFromCollection).not.toHaveBeenCalled();
  });

  it('passes the purchase definition through as the wallet layer expects it', async () => {
    const wallet = stubWallet([], { ownedIDs: ['bought_1'], ownedTraits: {} });
    const source = makeWalletOwnedAssetSource({ walletCollections: wallet });

    const unlocked = await source.listPurchasedTraits({
      delegateAddress: '0xdelegate',
      collectionName: 'anata',
      wallet: '0xabc',
    });

    expect(wallet.getSolanaPurchasedAssets).toHaveBeenCalledWith(
      { delegateAddress: '0xdelegate', collectionName: 'anata' },
      '0xabc',
    );
    expect(unlocked.ownedIDs).toEqual(['bought_1']);
  });

  it('reads a null answer as nothing unlocked', async () => {
    // getSolanaPurchasedAssets resolves with null when the read fails.
    const wallet = stubWallet([]);
    wallet.getSolanaPurchasedAssets = vi.fn(async () => null);
    const source = makeWalletOwnedAssetSource({ walletCollections: wallet });

    await expect(
      source.listPurchasedTraits({ delegateAddress: '0xd', collectionName: 'anata' }),
    ).resolves.toEqual({ ownedIDs: [], ownedTraits: {} });
  });
});
