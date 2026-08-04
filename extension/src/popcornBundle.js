/**
 * Where the built Popcorn bundle is, and whether it is there.
 *
 * This module holds no editor API on purpose. It takes paths and a
 * file check, and it returns an answer. That keeps the rule testable
 * without an editor host, which is the same split RFD 0023 makes
 * between a domain rule and an adapter.
 */
const path = require('node:path');
const fs = require('node:fs');

/**
 * Files the webview needs before it can start the VM.
 *
 * The esbuild plugin puts all of these in one flat folder, because the
 * AtomVM runtime resolves its own files from `import.meta.url`.
 */
const REQUIRED = ['index.js', 'bundle.avm', 'AtomVM.mjs', 'AtomVM.wasm', 'iframe.mjs'];

/**
 * The folder that holds the built bundle.
 *
 * A configured path wins. It may be relative, and a relative path is
 * read against the workspace folder, because that is what a reader
 * means when they type one into settings.
 *
 * @param {object} options
 * @param {string} options.extensionPath
 * @param {string} [options.configured]
 * @param {string} [options.workspacePath]
 * @returns {string}
 */
function resolveDistPath({ extensionPath, configured, workspacePath }) {
  const setting = (configured || '').trim();

  if (!setting) {
    return path.join(extensionPath, 'popcorn', 'dist');
  }
  if (path.isAbsolute(setting)) {
    return setting;
  }
  return path.resolve(workspacePath || extensionPath, setting);
}

/**
 * Reports what the bundle folder is missing.
 *
 * An empty list means the webview can start. Anything else is the
 * reason it cannot, in the words the user needs to fix it.
 *
 * @param {string} distPath
 * @param {(p: string) => boolean} [exists]  Injected for tests.
 * @returns {string[]}
 */
function missingArtifacts(distPath, exists = fs.existsSync) {
  if (!distPath || !exists(distPath)) {
    return [...REQUIRED];
  }
  return REQUIRED.filter((name) => !exists(path.join(distPath, name)));
}

module.exports = { REQUIRED, resolveDistPath, missingArtifacts };
