/**
 * The composition step: the one place that picks adapters.
 *
 * Nothing else in the client imports an adapter. A consumer asks for
 * a port and gets whichever adapter this file chose, which is what
 * lets the choice change without touching a consumer.
 *
 * See RFD 0022.
 */
import { makeStaticCatalogSource } from './adapters/staticCatalogSource.js';
import { makeHttpCatalogSource } from './adapters/httpCatalogSource.js';

/**
 * Builds the CatalogSource for this environment.
 *
 * `VITE_STUDIO_API` names the studio core. Without it the client
 * takes the static list, so an existing setup keeps working and the
 * client still runs with no server.
 *
 * @param {{env?: Record<string, string|undefined>, fetch?: typeof globalThis.fetch}} [options]
 * @returns {import('./ports/catalogSource.contract.js').CatalogSource}
 */
export function makeCatalogSource(options = {}) {
  const env = options.env ?? safeEnv();
  const baseUrl = env.VITE_STUDIO_API;

  if (!baseUrl) {
    return makeStaticCatalogSource();
  }

  return makeHttpCatalogSource({ baseUrl, fetch: options.fetch });
}

/**
 * `import.meta.env` under Vite, and an empty object anywhere else.
 *
 * Node tooling and the Electron main process load this file without
 * Vite, so reading the variable directly would throw there.
 */
function safeEnv() {
  try {
    return import.meta.env ?? {};
  } catch {
    return {};
  }
}
