import * as esbuild from "esbuild";
import { popcorn } from "@swmansion/popcorn/esbuild";
import { copyFile, mkdir } from "node:fs/promises";

// `popcorn.cook` writes the bundle to ../dist/wasm. The esbuild plugin
// copies it, and the AtomVM runtime, next to the bundled script,
// because the runtime resolves its own files from import.meta.url.
await mkdir("../dist", { recursive: true });
await copyFile("index.html", "../dist/index.html");

await esbuild.build({
  entryPoints: ["index.js"],
  bundle: true,
  format: "esm",
  sourcemap: true,
  outfile: "../dist/index.js",
  plugins: [popcorn({ bundlePaths: ["../dist/wasm/bundle.avm"] })],
});
