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

function stubWallet(owned) {
  return { getOwnedTraitIDs: vi.fn(async () => owned) };
}

describeOwnedAssetSourceContract('null', () => makeNullOwnedAssetSource());

describeOwnedAssetSourceContract('wallet', () =>
  makeWalletOwnedAssetSource({
    collections: COLLECTIONS,
    walletCollections: stubWallet(['trait_a', 'trait_b']),
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
});
