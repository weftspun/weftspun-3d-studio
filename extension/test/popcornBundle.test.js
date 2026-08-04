/**
 * The bundle rules, without an editor.
 *
 * These run under `node --test`, because the module they cover takes
 * no editor API. That is the point of keeping it separate.
 */
const test = require('node:test');
const assert = require('node:assert');
const path = require('node:path');

const { REQUIRED, resolveDistPath, missingArtifacts } = require('../src/popcornBundle');

test('the default folder is popcorn/dist inside the extension', () => {
  const dist = resolveDistPath({ extensionPath: path.join('/ext') });

  assert.strictEqual(dist, path.join('/ext', 'popcorn', 'dist'));
});

test('an empty setting counts as unset', () => {
  const dist = resolveDistPath({ extensionPath: path.join('/ext'), configured: '   ' });

  assert.strictEqual(dist, path.join('/ext', 'popcorn', 'dist'));
});

test('an absolute setting wins', () => {
  const absolute = path.resolve('/elsewhere/dist');
  const dist = resolveDistPath({ extensionPath: path.join('/ext'), configured: absolute });

  assert.strictEqual(dist, absolute);
});

test('a relative setting reads against the workspace', () => {
  const dist = resolveDistPath({
    extensionPath: path.join('/ext'),
    configured: 'build/wasm',
    workspacePath: path.resolve('/work'),
  });

  assert.strictEqual(dist, path.resolve('/work', 'build/wasm'));
});

test('a missing folder reports every artifact', () => {
  const missing = missingArtifacts(path.join('/nope'), () => false);

  assert.deepStrictEqual(missing, REQUIRED);
});

test('a complete folder reports nothing', () => {
  const missing = missingArtifacts(path.join('/dist'), () => true);

  assert.deepStrictEqual(missing, []);
});

test('a partial folder names only what is absent', () => {
  const dist = path.join('/dist');
  const present = new Set([dist, ...REQUIRED.slice(1).map((n) => path.join(dist, n))]);

  const missing = missingArtifacts(dist, (p) => present.has(p));

  assert.deepStrictEqual(missing, [REQUIRED[0]]);
});

test('the runtime files AtomVM needs are all required', () => {
  // The panel starts the VM only when these exist. A build that
  // dropped one would otherwise show an empty panel.
  for (const name of ['index.js', 'bundle.avm', 'AtomVM.wasm', 'AtomVM.mjs', 'iframe.mjs']) {
    assert.ok(REQUIRED.includes(name), `${name} must be required`);
  }
});
