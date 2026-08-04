/**
 * The CatalogSource port, as a contract test.
 *
 * JavaScript has no interfaces, so this suite *is* the port. Every
 * adapter runs it. An adapter that passes is usable in its place.
 *
 * Mirrors `WeftspunStudio.Ports.CatalogSource` on the Elixir side, so
 * a reader of one side can read the other. See RFD 0022.
 *
 * @typedef {object} CatalogEntry
 * @property {string} value   Model id, such as `trellis_text_to_textured_mesh`.
 * @property {string} label   Human readable name for the picker.
 * @property {string} feature Feature the model serves.
 *
 * @typedef {object} CatalogSource
 * @property {() => Promise<CatalogEntry[]>} listModels
 * @property {() => Promise<string[]>} listFeatures
 * @property {(feature: string) => Promise<CatalogEntry[]>} listModelsForFeature
 */

import { describe, it, expect } from 'vitest';

/**
 * Runs the whole CatalogSource port against one adapter.
 *
 * @param {string} name    Adapter name, for the test output.
 * @param {() => CatalogSource | Promise<CatalogSource>} makeSource
 */
export function describeCatalogSourceContract(name, makeSource) {
  describe(`CatalogSource contract: ${name}`, () => {
    it('listModels returns a non-empty array', async () => {
      const source = await makeSource();
      const models = await source.listModels();

      expect(Array.isArray(models)).toBe(true);
      expect(models.length).toBeGreaterThan(0);
    });

    it('every entry carries value, label, and feature as strings', async () => {
      const source = await makeSource();
      const models = await source.listModels();

      for (const entry of models) {
        expect(typeof entry.value).toBe('string');
        expect(typeof entry.label).toBe('string');
        expect(typeof entry.feature).toBe('string');
        expect(entry.value.length).toBeGreaterThan(0);
      }
    });

    it('model ids are unique', async () => {
      const source = await makeSource();
      const ids = (await source.listModels()).map((m) => m.value);

      expect(new Set(ids).size).toBe(ids.length);
    });

    it('listFeatures returns every feature the models name, and no more', async () => {
      const source = await makeSource();
      const [models, features] = await Promise.all([
        source.listModels(),
        source.listFeatures(),
      ]);

      expect(new Set(features)).toEqual(new Set(models.map((m) => m.feature)));
    });

    it('listFeatures has no duplicates', async () => {
      const source = await makeSource();
      const features = await source.listFeatures();

      expect(new Set(features).size).toBe(features.length);
    });

    it('listModelsForFeature returns only models of that feature', async () => {
      const source = await makeSource();
      const features = await source.listFeatures();

      for (const feature of features) {
        const models = await source.listModelsForFeature(feature);

        expect(models.length).toBeGreaterThan(0);
        for (const entry of models) {
          expect(entry.feature).toBe(feature);
        }
      }
    });

    it('listModelsForFeature partitions listModels', async () => {
      const source = await makeSource();
      const features = await source.listFeatures();

      const gathered = [];
      for (const feature of features) {
        gathered.push(...(await source.listModelsForFeature(feature)));
      }

      const all = await source.listModels();
      expect(gathered.map((m) => m.value).sort()).toEqual(
        all.map((m) => m.value).sort(),
      );
    });

    it('an unknown feature gives an empty array, not a throw', async () => {
      const source = await makeSource();

      await expect(
        source.listModelsForFeature('no_such_feature_at_all'),
      ).resolves.toEqual([]);
    });

    it('a caller cannot mutate the source through a returned array', async () => {
      const source = await makeSource();

      const first = await source.listModels();
      first.push({ value: 'injected', label: 'Injected', feature: 'bogus' });

      const second = await source.listModels();
      expect(second.map((m) => m.value)).not.toContain('injected');
    });
  });
}
