/**
 * Driven adapter: the model catalog from the studio core.
 *
 * Reads `GET /api/v1/models` and `GET /api/v1/models/features` from
 * the Elixir server of RFD 0019. This is the direction the strangler
 * fig goes: the server holds the list, and the client reads it.
 *
 * Satisfies the CatalogSource port. See RFD 0022.
 */
import { entriesForFeature, featuresOf, freeze, isCatalogEntry } from '../domain/catalog.js';

const DEFAULT_TTL_MS = 60_000;

/**
 * @param {object} options
 * @param {string} options.baseUrl       Server root, such as `http://localhost:4000`.
 * @param {typeof globalThis.fetch} [options.fetch]
 * @param {number} [options.ttlMs]       How long a fetched list stays fresh.
 * @returns {import('../ports/catalogSource.contract.js').CatalogSource}
 */
export function makeHttpCatalogSource(options) {
  const { baseUrl, ttlMs = DEFAULT_TTL_MS } = options;
  const doFetch = options.fetch ?? globalThis.fetch;

  if (!baseUrl) {
    throw new Error('httpCatalogSource needs a baseUrl');
  }
  if (typeof doFetch !== 'function') {
    throw new Error('httpCatalogSource needs a fetch implementation');
  }

  // A picker reads the catalog on every render, so an uncached
  // adapter would put the list on the wire many times a second.
  const cache = new Map();

  async function getJson(path) {
    const hit = cache.get(path);
    if (hit && Date.now() - hit.at < ttlMs) {
      return hit.body;
    }

    const response = await doFetch(join(baseUrl, path));

    if (!response.ok) {
      throw new Error(`studio API ${path} failed with ${response.status}`);
    }

    const body = await response.json();
    cache.set(path, { at: Date.now(), body });
    return body;
  }

  async function models() {
    const body = await getJson('/api/v1/models');
    const list = Array.isArray(body?.models) ? body.models : [];

    // Reject a malformed payload at the boundary, so nothing bad
    // reaches the domain.
    return freeze(list.filter(isCatalogEntry));
  }

  return {
    async listModels() {
      return (await models()).map((entry) => ({ ...entry }));
    },

    async listFeatures() {
      const body = await getJson('/api/v1/models/features');

      // The server answers this directly, but the port promises the
      // features match the models exactly. Derive them when the
      // server says nothing, so the contract holds either way.
      if (Array.isArray(body?.features) && body.features.length > 0) {
        return [...new Set(body.features)];
      }
      return featuresOf(await models());
    },

    async listModelsForFeature(feature) {
      return entriesForFeature(await models(), feature);
    },
  };
}

/** Joins a base and a path with exactly one slash between them. */
function join(baseUrl, path) {
  return `${String(baseUrl).replace(/\/+$/, '')}${path}`;
}
