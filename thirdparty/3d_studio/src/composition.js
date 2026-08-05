/**
 * The composition root: the one place that picks adapters.
 *
 * Nothing else in the client imports an adapter. A consumer asks for
 * a port and gets whichever adapter this file chose, which is what
 * lets the choice change without touching a consumer.
 *
 * This file sits outside `src/core/` on purpose. It wires the chain
 * adapter, and RFD 0023 forbids the core from reaching chain code. A
 * composition root belongs outside the hexagon, because it is the
 * one place that must know every side.
 *
 * See RFD 0022 and RFD 0023.
 */
import { makeStaticCatalogSource } from './core/adapters/staticCatalogSource.js';
import { makeHttpCatalogSource } from './core/adapters/httpCatalogSource.js';
import { makeNullOwnedAssetSource } from './core/adapters/nullOwnedAssetSource.js';

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
 * Builds the OwnedAssetSource for this environment.
 *
 * `VITE_ENABLE_CHAIN` turns the wallet adapter on. Without it the
 * client takes the null adapter, so a content-only deployment runs
 * with no chain behaviour at all.
 *
 * The chain adapter loads through a dynamic import, so a build that
 * never enables the chain does not pull the wallet stack into the
 * first chunk.
 *
 * @param {{env?: Record<string, string|undefined>, collections?: object[]}} [options]
 * @returns {Promise<import('./core/ports/ownedAssetSource.contract.js').OwnedAssetSource>}
 */
export async function makeOwnedAssetSource(options = {}) {
  const env = options.env ?? safeEnv();

  if (env.VITE_ENABLE_CHAIN !== '1') {
    return makeNullOwnedAssetSource();
  }

  const { makeWalletOwnedAssetSource } = await import(
    './chain/adapters/walletOwnedAssetSource.js'
  );

  return makeWalletOwnedAssetSource({ collections: options.collections ?? [] });
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
