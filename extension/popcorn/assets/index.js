import { Popcorn } from "@swmansion/popcorn";

// The panel injects absolute URIs, because an editor webview serves
// files from a `vscode-webview:` origin and a relative path would miss
// them. A plain browser has no injector, so the file names below are
// the fallback, and they match what the esbuild plugin copies.
const config = globalThis.WEFTSPUN_POPCORN ?? {};
const bundlePaths = config.bundlePaths ?? ["./bundle.avm"];

const statusEl = document.getElementById("status");
const outputEl = document.getElementById("output");

function setStatus(text) {
  if (statusEl) statusEl.textContent = text;
}

/**
 * Elixir calls this when every check has run.
 *
 * The VM lives in a hidden same-origin iframe, so Elixir reaches this
 * through `window.parent`. That is why it hangs off the window and is
 * not a module-local function.
 */
globalThis.weftspunReport = (report) => {
  const failed = report.total - report.passed;
  setStatus(
    `${report.passed}/${report.total} checks passed — ` +
      `Elixir ${report.elixir}, OTP ${report.otp}, ${report.machine}`,
  );

  const rows = report.checks
    .map(
      (check) =>
        `<tr><td>${check.passed ? "PASS" : "FAIL"}</td>` +
        `<td>${escapeHtml(check.name)}</td>` +
        `<td><code>${escapeHtml(check.detail)}</code></td></tr>`,
    )
    .join("");

  if (outputEl) {
    outputEl.innerHTML = `<table>${rows}</table>`;
  }

  // The exit status of the minimal test, for anything that drives this
  // page from the outside.
  globalThis.WEFTSPUN_RESULT = { ...report, failed, ok: failed === 0 };
  document.body.dataset.weftspunResult = failed === 0 ? "pass" : "fail";
};

function escapeHtml(text) {
  return String(text).replace(
    /[&<>"']/g,
    (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c],
  );
}

setStatus("Starting the Elixir VM…");

try {
  await Popcorn.init({
    bundlePaths,
    wasmDir: config.wasmDir,
    onStdout: (message) => console.log("[elixir]", message),
    onStderr: (message) => console.error("[elixir]", message),
  });
} catch (error) {
  setStatus(`The Elixir VM did not start: ${error?.message ?? error}`);
  document.body.dataset.weftspunResult = "fail";
  throw error;
}
