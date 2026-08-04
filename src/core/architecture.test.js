/**
 * The hexagonal boundary, as a test.
 *
 * A rule that only a document states is a rule that decays. These
 * tests read the source and fail when the layout breaks.
 *
 * See RFD 0022 and RFD 0023.
 */
import { describe, it, expect } from 'vitest';
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join, relative, resolve } from 'node:path';

// Vitest rewrites import.meta.url to a served path, so deriving the
// directory from it gives "/src". Resolve from the project root
// instead, which vitest sets as the working directory.
const SRC = resolve(process.cwd(), 'src');
const CORE = join(SRC, 'core');
const CHAIN = join(SRC, 'chain');

/** Libraries that reach a blockchain. */
const CHAIN_LIBS = ['thirdweb', 'ethers', '@solana/web3.js', '@web3-react'];

/**
 * Modules in src/library/ that still import chain code.
 *
 * RFD 0023 records this debt. The list may only shrink. Adding a
 * name here is a decision, not a fix.
 */
const KNOWN_CHAIN_LEAKS = [
  'library/characterManager.js',
  'library/CharacterManifestData.js',
  'library/sceneManager.js',
  'pages/Load.jsx',
];

/**
 * Every JavaScript file under a directory.
 *
 * This throws when the directory is missing. An earlier version
 * returned an empty list, and every test below then passed while
 * reading nothing. A guard that checks nothing is worse than no
 * guard.
 */
function walk(dir) {
  const out = [];
  const entries = readdirSync(dir);

  for (const entry of entries) {
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) {
      out.push(...walk(full));
    } else if (/\.(js|jsx)$/.test(entry)) {
      out.push(full);
    }
  }
  return out;
}

/**
 * Import specifiers of one file.
 *
 * Comments come out first. A commented-out import is not a
 * dependency, and counting one would report a leak that does not
 * exist.
 */
function importsOf(file) {
  const source = readFileSync(file, 'utf8')
    .replace(/\/\*[\s\S]*?\*\//g, '')
    .replace(/^\s*\/\/.*$/gm, '');

  return [...source.matchAll(/(?:from|import)\s*\(?\s*['"]([^'"]+)['"]/g)].map((m) => m[1]);
}

function importsChainLib(specifiers) {
  return specifiers.filter((s) => CHAIN_LIBS.some((lib) => s === lib || s.startsWith(`${lib}/`)));
}

describe('the guard reads real files', () => {
  it('finds source under src/core and src/library', () => {
    // Without this, a path bug makes every test below pass vacuously.
    expect(walk(CORE).length).toBeGreaterThan(3);
    expect(walk(join(SRC, 'library')).length).toBeGreaterThan(50);
    expect(walk(CHAIN).length).toBeGreaterThan(5);
  });

  it('sees the imports of a known file', () => {
    const specs = importsOf(join(SRC, 'library', 'characterManager.js'));

    expect(specs.length).toBeGreaterThan(0);
  });
});

describe('src/core does not depend on a chain', () => {
  it('imports no chain library', () => {
    const offenders = [];

    for (const file of walk(CORE)) {
      const bad = importsChainLib(importsOf(file));
      if (bad.length > 0) {
        offenders.push(`${relative(SRC, file)} -> ${bad.join(', ')}`);
      }
    }

    expect(offenders).toEqual([]);
  });

  it('imports nothing from src/chain', () => {
    const offenders = [];

    for (const file of walk(CORE)) {
      const bad = importsOf(file).filter((s) => /(^|\/)chain\//.test(s));
      if (bad.length > 0) {
        offenders.push(`${relative(SRC, file)} -> ${bad.join(', ')}`);
      }
    }

    expect(offenders).toEqual([]);
  });
});

describe('src/core/domain holds pure rules', () => {
  const DOMAIN = join(CORE, 'domain');

  it('imports nothing outside domain', () => {
    const offenders = [];

    for (const file of walk(DOMAIN)) {
      const bad = importsOf(file).filter(
        (s) => s.startsWith('.') && (s.includes('../') || s.includes('/adapters/')),
      );
      if (bad.length > 0) {
        offenders.push(`${relative(SRC, file)} -> ${bad.join(', ')}`);
      }
    }

    expect(offenders).toEqual([]);
  });

  it('imports no React and no three.js', () => {
    const offenders = [];

    for (const file of walk(DOMAIN)) {
      const bad = importsOf(file).filter((s) => ['react', 'three'].includes(s));
      if (bad.length > 0) {
        offenders.push(`${relative(SRC, file)} -> ${bad.join(', ')}`);
      }
    }

    expect(offenders).toEqual([]);
  });
});

describe('the chain leak into src/library', () => {
  it('has not grown', () => {
    const found = [];

    for (const file of walk(join(SRC, 'library'))) {
      const specifiers = importsOf(file);
      const touchesChain =
        importsChainLib(specifiers).length > 0 ||
        specifiers.some((s) => /(^|\/)chain\//.test(s));

      if (touchesChain) {
        found.push(relative(SRC, file));
      }
    }

    const surprises = found.filter((f) => !KNOWN_CHAIN_LEAKS.includes(f));
    expect(surprises).toEqual([]);
  });

  it('lists no name that is already clean', () => {
    // Keeps the list honest: a fixed module must leave the list.
    const stale = KNOWN_CHAIN_LEAKS.filter((name) => {
      const file = join(SRC, name);
      let specifiers;
      try {
        specifiers = importsOf(file);
      } catch {
        return true;
      }
      return (
        importsChainLib(specifiers).length === 0 &&
        !specifiers.some((s) => /(^|\/)chain\//.test(s))
      );
    });

    expect(stale).toEqual([]);
  });
});

describe('src/chain is the only home for chain libraries', () => {
  it('every module that imports a chain library sits in src/chain, or is a known leak', () => {
    const offenders = [];

    for (const file of walk(SRC)) {
      const rel = relative(SRC, file);
      if (rel.startsWith('chain/') || rel.includes('__tests__') || rel.endsWith('.test.js')) {
        continue;
      }
      if (KNOWN_CHAIN_LEAKS.includes(rel)) continue;

      if (importsChainLib(importsOf(file)).length > 0) {
        offenders.push(rel);
      }
    }

    expect(offenders).toEqual([]);
  });
});
