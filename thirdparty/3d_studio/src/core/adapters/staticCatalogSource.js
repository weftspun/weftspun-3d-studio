/**
 * Driven adapter: the model catalog the client already ships.
 *
 * Reads `src/library/aiModelsCatalog.js`, so this adapter needs no
 * server and today's behaviour does not change. It is the fallback
 * when `VITE_STUDIO_API` is unset, and the offline path.
 *
 * Satisfies the CatalogSource port. See RFD 0022.
 */
import { ALL_MODELS } from '../../library/aiModelsCatalog.js';
import { entriesForFeature, featuresOf, freeze } from '../domain/catalog.js';

/**
 * @param {{ entries?: import('../ports/catalogSource.contract.js').CatalogEntry[] }} [options]
 * @returns {import('../ports/catalogSource.contract.js').CatalogSource}
 */
export function makeStaticCatalogSource(options = {}) {
  // Copy once at construction. The module-level ALL_MODELS is shared
  // with the rest of the client, so the port must not hand out a
  // reference a caller could mutate.
  const entries = freeze(options.entries ?? ALL_MODELS);

  return {
    async listModels() {
      return entries.map((entry) => ({ ...entry }));
    },

    async listFeatures() {
      return featuresOf(entries);
    },

    async listModelsForFeature(feature) {
      return entriesForFeature(entries, feature);
    },
  };
}
