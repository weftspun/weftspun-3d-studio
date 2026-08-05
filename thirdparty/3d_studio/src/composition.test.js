/**
 * The composition step picks an adapter from the environment.
 * See RFD 0022.
 */
import { describe, it, expect, vi } from 'vitest';

import { makeCatalogSource, makeOwnedAssetSource } from './composition.js';

describe('makeCatalogSource', () => {
  it('takes the static list when VITE_STUDIO_API is unset', async () => {
    const source = makeCatalogSource({ env: {} });
    const fetchSpy = vi.spyOn(globalThis, 'fetch');

    await source.listModels();

    expect(fetchSpy).not.toHaveBeenCalled();
    fetchSpy.mockRestore();
  });

  it('takes the HTTP adapter when VITE_STUDIO_API is set', async () => {
    const fetchStub = vi.fn(
      async () =>
        new Response(JSON.stringify({ models: [] }), {
          status: 200,
          headers: { 'Content-Type': 'application/json' },
        }),
    );

    const source = makeCatalogSource({
      env: { VITE_STUDIO_API: 'http://localhost:4000' },
      fetch: fetchStub,
    });
    await source.listModels();

    expect(String(fetchStub.mock.calls[0][0])).toBe('http://localhost:4000/api/v1/models');
  });

  it('an empty VITE_STUDIO_API counts as unset', async () => {
    const source = makeCatalogSource({ env: { VITE_STUDIO_API: '' } });

    await expect(source.listModels()).resolves.toBeInstanceOf(Array);
  });
});

describe('makeOwnedAssetSource', () => {
  it('takes the null adapter when VITE_ENABLE_CHAIN is unset', async () => {
    const source = await makeOwnedAssetSource({ env: {} });

    expect(source.isEnabled()).toBe(false);
    await expect(source.listOwnedTraitIds('0xabc')).resolves.toEqual([]);
  });

  it('takes the wallet adapter when VITE_ENABLE_CHAIN is 1', async () => {
    const source = await makeOwnedAssetSource({
      env: { VITE_ENABLE_CHAIN: '1' },
      collections: [{ id: 'anata', name: 'Anata' }],
    });

    expect(source.isEnabled()).toBe(true);
    await expect(source.listCollections()).resolves.toEqual([{ id: 'anata', name: 'Anata' }]);
  });

  it('treats any other value as off', async () => {
    const source = await makeOwnedAssetSource({ env: { VITE_ENABLE_CHAIN: 'true' } });

    expect(source.isEnabled()).toBe(false);
  });

  it('the null adapter unlocks no trait for any manifest', async () => {
    // What a content-only deployment shows: the locked set. A manifest
    // still loads, and the picker offers what is not locked.
    const source = await makeOwnedAssetSource({ env: {} });

    await expect(
      source.listCollectionTraits({
        collectionId: 'anata',
        chainName: 'ethereum',
        dataSource: 'attributes',
      }),
    ).resolves.toEqual({ ownedIDs: [], ownedTraits: {} });
    await expect(
      source.listPurchasedTraits({ delegateAddress: '0xd', collectionName: 'anata' }),
    ).resolves.toEqual({ ownedIDs: [], ownedTraits: {} });
  });
});
