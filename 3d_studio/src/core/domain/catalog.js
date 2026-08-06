/**
 * Pure catalog rules.
 *
 * No network, no React, no three.js. Every adapter shares these, so
 * the two adapters cannot answer the same question differently.
 *
 * This file may import from `domain/` only. See RFD 0022.
 */

/**
 * A defensive copy that a caller cannot use to reach the original.
 *
 * The catalog entries are shared module state, so handing out a
 * reference would let one consumer edit another consumer's list.
 *
 * @template T
 * @param {T[]} entries
 * @returns {readonly T[]}
 */
export function freeze(entries) {
  return Object.freeze(entries.map((entry) => Object.freeze({ ...entry })));
}

/**
 * Every feature the entries name, in first-seen order, without
 * duplicates.
 *
 * @param {readonly {feature: string}[]} entries
 * @returns {string[]}
 */
export function featuresOf(entries) {
  return [...new Set(entries.map((entry) => entry.feature))];
}

/**
 * The entries that serve one feature.
 *
 * An unknown feature gives an empty array. A missing feature is a
 * normal answer for a picker, not an error.
 *
 * @template {{feature: string}} T
 * @param {readonly T[]} entries
 * @param {string} feature
 * @returns {T[]}
 */
export function entriesForFeature(entries, feature) {
  return entries
    .filter((entry) => entry.feature === feature)
    .map((entry) => ({ ...entry }));
}

/**
 * Orders models for a picker: the recommended one first, legacy last.
 *
 * The preferred model wins even when it is also legacy, because an
 * explicit recommendation beats a general rule.
 *
 * `Array.prototype.sort` is stable, so models that tie keep the order
 * the catalog gives them.
 *
 * @template {{value: string}} T
 * @param {readonly T[]} entries
 * @param {{preferredId?: string, legacyIds?: Set<string>}} [options]
 * @returns {T[]}
 */
export function sortRecommendedFirst(entries, options = {}) {
  const { preferredId, legacyIds = new Set() } = options;

  return [...entries].sort((a, b) => {
    if (a.value === preferredId) return -1;
    if (b.value === preferredId) return 1;
    return (legacyIds.has(a.value) ? 1 : 0) - (legacyIds.has(b.value) ? 1 : 0);
  });
}

/**
 * True when the entry has the three fields the port requires.
 *
 * The HTTP adapter uses this to reject a malformed payload at the
 * boundary, so no bad entry reaches the domain.
 *
 * @param {unknown} entry
 * @returns {boolean}
 */
export function isCatalogEntry(entry) {
  return (
    typeof entry === 'object' &&
    entry !== null &&
    typeof entry.value === 'string' &&
    entry.value.length > 0 &&
    typeof entry.label === 'string' &&
    typeof entry.feature === 'string'
  );
}
