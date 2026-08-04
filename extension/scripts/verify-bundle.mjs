/**
 * Runs the built bundle in a real browser, and fails when the Elixir
 * checks fail.
 *
 * The editor panel and this script load the same files the same way,
 * so a pass here means the panel has working artifacts. It does not
 * exercise the editor API, which `test/` covers separately.
 */
import { chromium } from '@playwright/test';
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
// path.resolve, so the prefix check below compares the separator style
// that path.join produces on this platform.
const dist = path.resolve(process.argv[2] ?? path.join(root, 'popcorn', 'dist'));

if (!fs.existsSync(path.join(dist, 'index.js'))) {
  console.error(`No build in ${dist}. Run "npm run build" first.`);
  process.exit(1);
}

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

  response.writeHead(200, {
    'Content-Type': TYPES[path.extname(file)] ?? 'application/octet-stream',
    // AtomVM wants a cross-origin isolated page for shared memory.
    'Cross-Origin-Opener-Policy': 'same-origin',
    'Cross-Origin-Embedder-Policy': 'require-corp',
    'Cross-Origin-Resource-Policy': 'cross-origin',
  });
  fs.createReadStream(file).pipe(response);
});

await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
const base = `http://127.0.0.1:${server.address().port}/`;

// channel: 'chromium', because the headless shell exposes navigator.gpu
// and then hands back no adapter. Only the full build has one.
const browser = await chromium.launch({ channel: 'chromium' });
const page = await browser.newPage();
page.on('pageerror', (error) => console.error('  [pageerror]', error.message));

let result = null;
try {
  await page.goto(base, { waitUntil: 'load' });
  await page.waitForFunction(() => document.body.dataset.weftspunResult !== undefined, null, {
    timeout: 120000,
  });
  result = await page.evaluate(() => globalThis.WEFTSPUN_RESULT ?? null);
} catch (error) {
  console.error('The VM did not report:', error.message.split('\n')[0]);
  console.error('status:', await page.textContent('#status').catch(() => '(no page)'));
} finally {
  await browser.close();
  server.close();
}

if (!result) {
  process.exit(1);
}

for (const check of result.checks) {
  console.log(`  ${check.passed ? 'PASS' : 'FAIL'}  ${check.name}  ${check.detail}`);
}
console.log(
  `\n${result.passed}/${result.total} passed on Elixir ${result.elixir}, ` +
    `OTP ${result.otp}, ${result.machine}, GPU ${result.gpu || 'none'}`,
);

process.exit(result.ok ? 0 : 1);
