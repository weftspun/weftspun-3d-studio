import { Popcorn } from "@swmansion/popcorn";
import { probeWebGpu, runKernel } from "./webgpu.js";

// The panel injects absolute URIs, because an editor webview serves
// files from a vscode-webview: origin and a relative path would miss
// them. A plain browser has no injector, so the names below are the
// fallback, and they match what the esbuild plugin copies.
const config = globalThis.WEFTSPUN_POPCORN ?? {};
const bundlePaths = config.bundlePaths ?? ["./bundle.avm"];

const statusEl = document.getElementById("status");
const vmEl = document.getElementById("vm");
const gpuEl = document.getElementById("gpu");
const kernelsEl = document.getElementById("kernels");

const setStatus = (text) => {
  if (statusEl) statusEl.textContent = text;
};

const escapeHtml = (text) =>
  String(text).replace(
    /[&<>"']/g,
    (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c],
  );

const rows = (checks) =>
  `<table>${checks
    .map(
      (check) =>
        `<tr><td class="${check.passed ? "pass" : "fail"}">` +
        `${check.passed ? "PASS" : "FAIL"}</td>` +
        `<td>${escapeHtml(check.name)}</td>` +
        `<td><code>${escapeHtml(check.detail)}</code></td></tr>`,
    )
    .join("")}</table>`;

/** Unwraps a popcorn.call, which reports failure in the result. */
async function callElixir(popcorn, args) {
  const result = await popcorn.call(args, { process: "main", timeoutMs: 30000 });
  if (!result.ok) {
    throw new Error(`Elixir call ${JSON.stringify(args)} failed: ${result.error}`);
  }
  return result.data;
}

// Carried into the result so an outside driver can report the same
// facts the panel shows.
const environment = { elixir: "", otp: "", machine: "", gpu: "" };

function finish(checks) {
  const failed = checks.filter((c) => !c.passed).length;
  globalThis.WEFTSPUN_RESULT = {
    ...environment,
    checks,
    total: checks.length,
    passed: checks.length - failed,
    failed,
    ok: failed === 0,
  };
  document.body.dataset.weftspunResult = failed === 0 ? "pass" : "fail";
  return failed;
}

// AtomVM is an emscripten build with pthreads, thus it needs
// SharedArrayBuffer, thus the page must be cross-origin isolated. An
// editor webview is not isolated by default, and an extension cannot
// set the headers that would make it so.
//
// Without this check the page waits 30 seconds and then reports a
// timeout, which does not name the cause. See the README.
if (!globalThis.crossOriginIsolated) {
  const reason =
    "this page is not cross-origin isolated, so SharedArrayBuffer is absent " +
    "and AtomVM cannot start its threads";
  setStatus("The Elixir VM cannot start here.");
  vmEl.innerHTML =
    `<p class="fail">${escapeHtml(reason)}.</p>` +
    `<p>An editor webview needs the <code>--enable-coi</code> flag. ` +
    `Close the editor, then start it again with that flag.</p>` +
    `<p class="dim">crossOriginIsolated: ${globalThis.crossOriginIsolated}, ` +
    `SharedArrayBuffer: ${typeof SharedArrayBuffer}</p>`;

  // The GPU needs no VM, thus report it anyway. It is the half of the
  // pipeline that does work here.
  const gpuOnly = await probeWebGpu();
  gpuEl.innerHTML = gpuOnly.supported
    ? `<p class="pass">${escapeHtml(gpuOnly.vendor)} ${escapeHtml(gpuOnly.architecture)}</p>`
    : `<p class="fail">${escapeHtml(gpuOnly.reason)}</p>`;

  environment.gpu = gpuOnly.supported
    ? `${gpuOnly.vendor} ${gpuOnly.architecture}`.trim()
    : "none";

  finish([
    { name: "cross-origin isolation", passed: false, detail: reason },
    {
      name: "webgpu adapter",
      passed: gpuOnly.supported,
      detail: gpuOnly.supported ? environment.gpu : gpuOnly.reason,
    },
  ]);
  throw new Error(reason);
}

setStatus("Starting the Elixir VM…");

let popcorn;
try {
  popcorn = await Popcorn.init({
    bundlePaths,
    wasmDir: config.wasmDir,
    onStdout: (message) => console.log("[elixir]", message),
    onStderr: (message) => console.error("[elixir]", message),
  });
} catch (error) {
  setStatus(`The Elixir VM did not start: ${error?.message ?? error}`);
  finish([{ name: "elixir vm", passed: false, detail: String(error) }]);
  throw error;
}

const all = [];

// 1. The VM, with no GPU involved.
const vm = await callElixir(popcorn, ["vm_checks"]);
vmEl.innerHTML = rows(vm.checks);
all.push(...vm.checks);
environment.elixir = vm.elixir;
environment.otp = vm.otp;
environment.machine = vm.machine;
setStatus(`Elixir ${vm.elixir}, OTP ${vm.otp}, ${vm.machine}. Checking the GPU…`);

// 2. What the runtime offers.
const gpu = await probeWebGpu();
if (!gpu.supported) {
  gpuEl.innerHTML =
    `<p class="fail">No WebGPU here: ${escapeHtml(gpu.reason)}</p>` +
    `<p>The Elixir checks above still ran.</p>`;
  setStatus(`Elixir ${vm.elixir} on ${vm.machine}. No WebGPU.`);
  environment.gpu = "none";
  all.push({ name: "webgpu adapter", passed: false, detail: gpu.reason });
  finish(all);
} else {
  gpuEl.innerHTML =
    `<p><b>${escapeHtml(gpu.vendor || "unknown vendor")}</b> ` +
    `${escapeHtml(gpu.architecture)} ${escapeHtml(gpu.description)}<br />` +
    `<span class="dim">max workgroup size x: ${gpu.maxWorkgroupSizeX}</span></p>`;
  environment.gpu = `${gpu.vendor} ${gpu.architecture}`.trim();
  all.push({ name: "webgpu adapter", passed: true, detail: environment.gpu });

  // 3. The kernels Elixir wrote.
  const device = await gpu.adapter.requestDevice();
  device.addEventListener?.("uncapturederror", (event) =>
    console.error("[webgpu]", event.error?.message ?? event),
  );

  const plan = await callElixir(popcorn, ["gpu_plan"]);
  const kernelChecks = [];

  for (const job of plan) {
    try {
      const actual = await runKernel(device, job);
      const verdict = await callElixir(popcorn, ["gpu_verify", job.name, actual]);
      kernelChecks.push({ name: job.name, passed: verdict.passed, detail: verdict.detail });
    } catch (error) {
      kernelChecks.push({ name: job.name, passed: false, detail: String(error?.message ?? error) });
    }
  }

  kernelsEl.innerHTML = rows(kernelChecks);
  all.push(...kernelChecks);

  const failed = finish(all);
  setStatus(
    `${all.length - failed}/${all.length} passed — Elixir ${vm.elixir} on ${vm.machine}, ` +
      `WGSL on ${gpu.vendor || "gpu"} ${gpu.architecture}`,
  );
}
