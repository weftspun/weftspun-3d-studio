/**
 * Pure catalog rules. No adapter, no network, no React.
 *
 * These run in milliseconds because nothing here does I/O, which is
 * the point of keeping the rules in `domain/`. See RFD 0022.
 */
import { describe, it, expect } from 'vitest';

import {
  entriesForFeature,
  featuresOf,
  freeze,
  isCatalogEntry,
  sortRecommendedFirst,
} from './catalog.js';

const ENTRIES = [
  { value: 'a_legacy', label: 'A legacy', feature: 'mesh' },
  { value: 'b_good', label: 'B good', feature: 'mesh' },
  { value: 'c_best', label: 'C best', feature: 'mesh' },
  { value: 'd_other', label: 'D other', feature: 'splat' },
];

describe('freeze', () => {
  it('gives a list a caller cannot edit', () => {
    const frozen = freeze(ENTRIES);

    expect(() => frozen.push({})).toThrow();
    expect(frozen.length).toBe(4);
  });

  it('freezes each entry, so a caller cannot edit one in place', () => {
    const frozen = freeze(ENTRIES);

    expect(() => {
      frozen[0].value = 'changed';
    }).toThrow();
  });

  it('does not edit the input', () => {
    const input = [{ value: 'x', label: 'X', feature: 'f' }];
    freeze(input);

    expect(Object.isFrozen(input)).toBe(false);
  });
});

describe('featuresOf', () => {
  it('lists each feature once, in first-seen order', () => {
    expect(featuresOf(ENTRIES)).toEqual(['mesh', 'splat']);
  });

  it('gives an empty list for no entries', () => {
    expect(featuresOf([])).toEqual([]);
  });
});

describe('entriesForFeature', () => {
  it('returns only that feature', () => {
    expect(entriesForFeature(ENTRIES, 'splat').map((e) => e.value)).toEqual(['d_other']);
  });

  it('returns an empty list for an unknown feature', () => {
    expect(entriesForFeature(ENTRIES, 'nope')).toEqual([]);
  });

  it('returns copies, so a caller cannot reach the source entries', () => {
    const [entry] = entriesForFeature(ENTRIES, 'splat');
    entry.label = 'edited';

    expect(ENTRIES[3].label).toBe('D other');
  });
});

describe('isCatalogEntry', () => {
  it('accepts a full entry', () => {
    expect(isCatalogEntry({ value: 'v', label: 'l', feature: 'f' })).toBe(true);
  });

  it.each([
    ['null', null],
    ['a string', 'nope'],
    ['a missing value', { label: 'l', feature: 'f' }],
    ['an empty value', { value: '', label: 'l', feature: 'f' }],
    ['a numeric value', { value: 1, label: 'l', feature: 'f' }],
    ['a missing feature', { value: 'v', label: 'l' }],
  ])('rejects %s', (_name, input) => {
    expect(isCatalogEntry(input)).toBe(false);
  });
});

describe('sortRecommendedFirst', () => {
  it('puts the preferred model first', () => {
    const sorted = sortRecommendedFirst(ENTRIES, { preferredId: 'c_best' });

    expect(sorted[0].value).toBe('c_best');
  });

  it('sinks legacy models below the rest', () => {
    const sorted = sortRecommendedFirst(ENTRIES, {
      preferredId: 'c_best',
      legacyIds: new Set(['a_legacy']),
    });

    expect(sorted[sorted.length - 1].value).toBe('a_legacy');
  });

  it('keeps the preferred model first even when it is legacy', () => {
    const sorted = sortRecommendedFirst(ENTRIES, {
      preferredId: 'a_legacy',
      legacyIds: new Set(['a_legacy']),
    });

    expect(sorted[0].value).toBe('a_legacy');
  });

  it('does not edit the input list', () => {
    const input = [...ENTRIES];
    sortRecommendedFirst(input, { preferredId: 'c_best' });

    expect(input.map((e) => e.value)).toEqual(ENTRIES.map((e) => e.value));
  });

  it('holds the order of models that tie', () => {
    const sorted = sortRecommendedFirst(ENTRIES, { preferredId: 'none' });

    expect(sorted.map((e) => e.value)).toEqual(ENTRIES.map((e) => e.value));
  });
});
