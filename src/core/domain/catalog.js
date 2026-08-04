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
