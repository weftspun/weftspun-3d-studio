/**
 * Runs the built bundle under the panel's Content Security Policy.
 *
 * `verify-bundle.mjs` serves the page with no policy, so it cannot
 * catch a policy that blocks the runtime. The editor panel always has
 * one. This script injects the same policy the panel writes, thus a
 * pass here means the policy allows the VM to start.
 *
 * Pass a policy on the command line to try another one.
 */
import { chromium } from '@playwright/test';
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
const dist = path.resolve(path.join(root, 'popcorn', 'dist'));

// Matches src/popcornPanel.js. `self` stands in for the webview origin,
// which is what `webview.cspSource` becomes there.
const DEFAULT_CSP = [
  "default-src 'none'",
  "img-src 'self' data:",
  "style-src 'self' 'unsafe-inline'",
  "script-src 'self' 'unsafe-inline' 'wasm-unsafe-eval' 'unsafe-eval'",
  "connect-src 'self' blob: data:",
  "frame-src 'self' data:",
  "worker-src 'self' blob:",
  "child-src 'self' blob:",
].join('; ');

const csp = process.argv[2] ?? DEFAULT_CSP;

const TYPES = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.mjs': 'text/javascript',
  '.wasm': 'application/wasm',
  '.avm': 'application/octet-stream',
  '.map': 'application/json',
};

const server = http.createServer((request, response) => {
  const rel = decodeURIComponent(request.url.split('?')[0]).replace(/^\/+/, '') || 'index.html';
  const file = path.join(dist, rel);

  if (!file.startsWith(dist) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) {
    response.writeHead(404).end('not found');
    return;
  }

  const headers = {
    'Content-Type': TYPES[path.extname(file)] ?? 'application/octet-stream',
  };

  // An editor webview sets no cross-origin isolation headers, thus a
  // test that sets them does not match the panel. WEFTSPUN_NO_COI=1
  // drops them, which is the panel's real condition.
  if (process.env.WEFTSPUN_NO_COI !== '1') {
    headers['Cross-Origin-Opener-Policy'] = 'same-origin';
    headers['Cross-Origin-Embedder-Policy'] = 'require-corp';
    headers['Cross-Origin-Resource-Policy'] = 'cross-origin';
  }

  // Only the document carries the policy, the same as the panel.
  if (path.extname(file) === '.html') {
    headers['Content-Security-Policy'] = csp;
  }

  response.writeHead(200, headers);
  fs.createReadStream(file).pipe(response);
});

await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
const base = `http://127.0.0.1:${server.address().port}/`;

console.log(`policy: ${csp}\n`);

const browser = await chromium.launch({ channel: 'chromium' });
const page = await browser.newPage();

const violations = [];
page.on('console', (message) => {
  const text = message.text();
  if (/Content Security Policy|Refused to/i.test(text)) {
    violations.push(text.split('\n')[0].slice(0, 200));
  }
});
page.on('pageerror', (error) => console.error('  [pageerror]', error.message));

let result = null;
try {
  await page.goto(base, { waitUntil: 'load' });
  await page.waitForFunction(() => document.body.dataset.weftspunResult !== undefined, null, {
    timeout: 60000,
  });
  result = await page.evaluate(() => globalThis.WEFTSPUN_RESULT ?? null);
} catch (error) {
  console.error('The VM did not report:', error.message.split('\n')[0]);
  console.error('status:', await page.textContent('#status').catch(() => '(no page)'));
} finally {
  await browser.close();
  server.close();
}

if (violations.length > 0) {
  console.error('\nPolicy violations:');
  for (const violation of [...new Set(violations)]) {
    console.error(`  ${violation}`);
  }
}

if (!result) {
  console.error('\nThe policy blocks the runtime.');
  process.exit(1);
}

for (const check of result.checks) {
  console.log(`  ${check.passed ? 'PASS' : 'FAIL'}  ${check.name}  ${check.detail}`);
}
console.log(`\n${result.passed}/${result.total} passed under the panel policy`);
process.exit(result.ok ? 0 : 1);
