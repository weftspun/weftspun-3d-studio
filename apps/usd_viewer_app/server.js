// SPDX-License-Identifier: MIT
// Copyright (c) 2026 K. S. Ernest (iFire) Lee
//
// The whole runtime this app needs: a static file server for
// dist/, at the same /gallery/* paths weftspun_studio's own
// GallerySource adapter (RFD 0076) forwards unchanged. No
// framework, no dependency; a Vite-built SPA is a directory of
// files and a mime type, nothing more.
//
// COEP/COOP are set here too, not only by the weftspun_studio
// proxy in front of this, so a developer can open this app's own
// URL directly and still get a working usd-viewer WASM build
// (SharedArrayBuffer needs both headers).

import { createServer } from "node:http";
import { readFile, stat } from "node:fs/promises";
import { join, extname, normalize } from "node:path";
import { fileURLToPath } from "node:url";

const DIST = join(fileURLToPath(new URL(".", import.meta.url)), "dist");
const PORT = Number(process.env.PORT || 8090);

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".wasm": "application/wasm",
  ".data": "application/octet-stream",
  ".usd": "model/vnd.usd",
  ".usda": "model/vnd.usd",
  ".usdz": "model/vnd.usdz+zip",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".txt": "text/plain; charset=utf-8",
  ".md": "text/plain; charset=utf-8",
};

async function resolveFile(urlPath) {
  // "/", "/gallery", "/gallery/" all mean the app's own index, the
  // same alias weftspun_studio's router already forwards. Every
  // other request under /gallery/ maps straight onto dist/.
  if (urlPath === "/" || urlPath === "/gallery" || urlPath === "/gallery/") {
    return join(DIST, "index.html");
  }
  if (!urlPath.startsWith("/gallery/")) {
    return null;
  }
  // normalize collapses a "../" traversal attempt; reject anything
  // that still climbs out of dist/ after that.
  const rel = normalize(urlPath.slice("/gallery/".length));
  if (rel.startsWith("..")) {
    return null;
  }
  return join(DIST, rel);
}

const server = createServer(async (req, res) => {
  const url = new URL(req.url, "http://localhost");

  if (url.pathname === "/health") {
    res.writeHead(200, { "content-type": "text/plain" }).end("ok");
    return;
  }

  const filePath = await resolveFile(url.pathname);
  if (!filePath) {
    res.writeHead(404, { "content-type": "text/plain" }).end("not found");
    return;
  }

  try {
    const stats = await stat(filePath);
    if (!stats.isFile()) throw new Error("not a file");
    const body = await readFile(filePath);
    res
      .writeHead(200, {
        "content-type": MIME[extname(filePath)] || "application/octet-stream",
        "cross-origin-embedder-policy": "require-corp",
        "cross-origin-opener-policy": "same-origin",
      })
      .end(body);
  } catch {
    res.writeHead(404, { "content-type": "text/plain" }).end("not found");
  }
});

server.listen(PORT, () => {
  console.log(`usd_viewer_app serving dist/ at :${PORT}, under /gallery/`);
});
