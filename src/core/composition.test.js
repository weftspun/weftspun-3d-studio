/**
 * The composition step picks an adapter from the environment.
 * See RFD 0022.
 */
import { describe, it, expect, vi } from 'vitest';

import { makeCatalogSource } from './composition.js';

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
