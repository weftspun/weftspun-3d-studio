/**
 * The panel that runs the minimal test.
 *
 * Popcorn compiles this project's Elixir to an AtomVM bundle and
 * starts it in WebAssembly. The checks run there, and the panel shows
 * what came back.
 */
const path = require('node:path');
const vscode = require('vscode');
const { resolveDistPath, missingArtifacts } = require('./popcornBundle');

/** @type {import('vscode').WebviewPanel | undefined} */
let panel;

/**
 * @param {import('vscode').ExtensionContext} context
 * @returns {import('vscode').WebviewPanel | undefined}
 */
function openMinimalTestPanel(context) {
  if (panel) {
    panel.reveal(vscode.ViewColumn.One);
    return panel;
  }

  const distPath = resolveDistPath({
    extensionPath: context.extensionPath,
    configured: vscode.workspace.getConfiguration('weftspun').get('popcorn.distPath'),
    workspacePath: vscode.workspace.workspaceFolders?.[0]?.uri.fsPath,
  });

  const missing = missingArtifacts(distPath);
  if (missing.length > 0) {
    // The VM cannot start without these, and an empty panel does not
    // say why. Report what is absent, and where it was expected.
    vscode.window.showErrorMessage(
      `Weftspun: the Popcorn build is incomplete. Missing ${missing.join(', ')} in ${distPath}. ` +
        'Run "npm run build" in the extension folder.',
    );
    return undefined;
  }

  panel = vscode.window.createWebviewPanel(
    'weftspun.minimalTest',
    'Weftspun Minimal Test',
    vscode.ViewColumn.One,
    {
      enableScripts: true,
      retainContextWhenHidden: true,
      localResourceRoots: [vscode.Uri.file(distPath)],
    },
  );

  panel.webview.html = renderHtml(panel.webview, distPath);
  panel.onDidDispose(() => {
    panel = undefined;
  });

  return panel;
}

/**
 * The page for the panel.
 *
 * @param {import('vscode').Webview} webview
 * @param {string} distPath
 * @returns {string}
 */
function renderHtml(webview, distPath) {
  const asUri = (...parts) =>
    webview.asWebviewUri(vscode.Uri.file(path.join(distPath, ...parts))).toString();

  // This policy is the one `scripts/verify-csp.mjs` runs the bundle
  // under. Every permission here answers a block that a stricter
  // policy caused, and each block stopped the VM from starting.
  //
  // `unsafe-inline` and no nonce: Popcorn runs the VM in a hidden
  // `srcdoc` iframe, and it writes an inline module script into that
  // frame. A `srcdoc` frame inherits this policy. A nonce in
  // `script-src` makes the browser ignore `unsafe-inline`, thus a
  // nonce here blocks the frame that holds the VM.
  //
  // `wasm-unsafe-eval` is for AtomVM, which is WebAssembly.
  // `unsafe-eval` is for the bridge, which evaluates the function
  // Elixir sends through run_js.
  //
  // `worker-src` names the webview origin, and not only `blob:`,
  // because AtomVM starts its worker from `AtomVM.mjs`.
  const csp = [
    "default-src 'none'",
    `img-src ${webview.cspSource} data:`,
    `style-src ${webview.cspSource} 'unsafe-inline'`,
    `script-src ${webview.cspSource} 'unsafe-inline' 'wasm-unsafe-eval' 'unsafe-eval'`,
    `connect-src ${webview.cspSource} blob: data:`,
    `frame-src ${webview.cspSource} 'self' data:`,
    `worker-src ${webview.cspSource} blob:`,
    `child-src ${webview.cspSource} blob:`,
  ].join('; ');

  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8" />
<meta http-equiv="Content-Security-Policy" content="${csp}" />
<title>Weftspun Minimal Test</title>
<style>
  body {
    font-family: var(--vscode-font-family);
    color: var(--vscode-foreground);
    background: var(--vscode-editor-background);
    padding: 1rem 1.25rem;
    line-height: 1.5;
  }
  h1 { font-size: 1.2rem; margin: 0 0 0.5rem; }
  h2 { font-size: 1rem; margin: 1.2rem 0 0.3rem; }
  #status { opacity: 0.75; font-size: 0.9em; }
  table { border-collapse: collapse; margin-top: 0.3rem; width: 100%; }
  td {
    border-bottom: 1px solid var(--vscode-panel-border, #3c3c3c);
    padding: 0.3rem 0.6rem;
    vertical-align: top;
  }
  td:first-child { width: 4rem; font-weight: 600; }
  .pass { color: var(--vscode-testing-iconPassed, #4ec9b0); }
  .fail { color: var(--vscode-testing-iconFailed, #f48771); }
  .dim { opacity: 0.7; }
</style>
</head>
<body>
  <h1>Weftspun minimal test</h1>
  <p id="status">Loading…</p>
  <h2>Elixir VM</h2>
  <div id="vm"></div>
  <h2>WebGPU adapter</h2>
  <div id="gpu"></div>
  <h2>WGSL kernels, written by Elixir</h2>
  <div id="kernels"></div>
  <script>
    // An editor webview serves files from a vscode-webview: origin, so
    // the runtime needs absolute URIs. A relative path would miss.
    window.WEFTSPUN_POPCORN = {
      bundlePaths: ["${asUri('bundle.avm')}"],
      wasmDir: "${asUri('')}"
    };
  </script>
  <script type="module" src="${asUri('index.js')}"></script>
</body>
</html>`;
}

module.exports = { openMinimalTestPanel, renderHtml };
