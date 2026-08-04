/**
 * Builds the Elixir bundle and the page that loads it.
 *
 * Popcorn 0.3.2 raises unless it sees OTP 26.0.2 and Elixir 1.17.3,
 * so `popcorn/mise.toml` pins both. This script calls mise when it is
 * present, and falls back to a plain `mix` when it is not.
 */
import { spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const popcornDir = join(root, 'popcorn');
const assetsDir = join(popcornDir, 'assets');
const windows = process.platform === 'win32';

function run(command, args, cwd) {
  const result = spawnSync(command, args, { cwd, stdio: 'inherit', shell: windows });
  if (result.status !== 0) {
    console.error(`\nFailed: ${command} ${args.join(' ')} (in ${cwd})`);
    process.exit(result.status ?? 1);
  }
}

function hasMise() {
  return spawnSync('mise', ['--version'], { stdio: 'ignore', shell: windows }).status === 0;
}

const mix = hasMise() ? ['mise', ['exec', '--', 'mix']] : ['mix', []];
if (mix[0] === 'mix') {
  console.warn('mise not found. Using the mix on PATH, which must be Elixir 1.17.3 on OTP 26.0.2.');
}

run(mix[0], [...mix[1], 'deps.get'], popcornDir);
run(mix[0], [...mix[1], 'popcorn.cook'], popcornDir);

const npm = windows ? 'npm.cmd' : 'npm';
if (!existsSync(join(assetsDir, 'node_modules'))) {
  run(npm, ['install'], assetsDir);
}
run(npm, ['run', 'build'], assetsDir);

console.log('\nBuilt into extension/popcorn/dist');
