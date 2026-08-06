/**
 * Both CatalogSource adapters run the same port contract.
 *
 * This is the point of the port: an adapter is interchangeable
 * exactly when it passes. See RFD 0022.
 */
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';

import { describeCatalogSourceContract } from '../ports/catalogSource.contract.js';
import { makeStaticCatalogSource } from './staticCatalogSource.js';
import { makeHttpCatalogSource } from './httpCatalogSource.js';

// The HTTP adapter runs the contract against a stub server that
// answers the way the Elixir router does.
const API_MODELS = [
  { value: 'trellis_text_to_textured_mesh', label: 'TRELLIS Text to Textured Mesh', feature: 'text_to_textured_mesh' },
  { value: 'trellis2_image_to_textured_mesh', label: 'TRELLIS.2 Image to Textured Mesh', feature: 'image_to_textured_mesh' },
  { value: 'xatlas_uv_unwrapping', label: 'xatlas UV Unwrapping', feature: 'uv_unwrapping' },
];

function stubFetch() {
  return vi.fn(async (url) => {
    const path = new URL(url, 'http://studio.test').pathname;

    if (path === '/api/v1/models') {
      return jsonResponse({ models: API_MODELS });
    }
    if (path === '/api/v1/models/features') {
      return jsonResponse({ features: [...new Set(API_MODELS.map((m) => m.feature))] });
    }
    return new Response('{"error":"not found"}', { status: 404 });
  });
}

function jsonResponse(body) {
  return new Response(JSON.stringify(body), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
}

describeCatalogSourceContract('static', () => makeStaticCatalogSource());

describeCatalogSourceContract('http', () =>
  makeHttpCatalogSource({ baseUrl: 'http://studio.test', fetch: stubFetch() }),
);

// Behaviour that belongs to one adapter only sits outside the
// contract, so the contract stays the shared part.
describe('staticCatalogSource', () => {
  it('serves the list the client already ships', async () => {
    const source = makeStaticCatalogSource();
    const ids = (await source.listModels()).map((m) => m.value);

    expect(ids).toContain('trellis_text_to_textured_mesh');
  });

  it('needs no network', async () => {
    const source = makeStaticCatalogSource({ fetch: undefined });

    await expect(source.listModels()).resolves.toBeInstanceOf(Array);
  });
});

describe('httpCatalogSource', () => {
  let fetchStub;

  beforeEach(() => {
    fetchStub = stubFetch();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('reads GET /api/v1/models', async () => {
    const source = makeHttpCatalogSource({ baseUrl: 'http://studio.test', fetch: fetchStub });
    await source.listModels();

    expect(fetchStub).toHaveBeenCalled();
    const called = String(fetchStub.mock.calls[0][0]);
    expect(called).toContain('/api/v1/models');
  });

  it('joins the base url without doubling a slash', async () => {
    const source = makeHttpCatalogSource({ baseUrl: 'http://studio.test/', fetch: fetchStub });
    await source.listModels();

    expect(String(fetchStub.mock.calls[0][0])).toBe('http://studio.test/api/v1/models');
  });

  it('rejects with a useful message when the server errors', async () => {
    const failing = vi.fn(async () => new Response('nope', { status: 500 }));
    const source = makeHttpCatalogSource({ baseUrl: 'http://studio.test', fetch: failing });

    await expect(source.listModels()).rejects.toThrow(/500/);
  });

  it('does not refetch on a second call within the cache window', async () => {
    const source = makeHttpCatalogSource({ baseUrl: 'http://studio.test', fetch: fetchStub });

    await source.listModels();
    await source.listModels();

    const modelCalls = fetchStub.mock.calls.filter(([u]) =>
      String(u).endsWith('/api/v1/models'),
    );
    expect(modelCalls.length).toBe(1);
  });
});
