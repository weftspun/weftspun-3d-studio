import { defineConfig } from "vite";

// This app is always served under a /gallery/ prefix: by
// server.js's own mount (RFD 0076), and, through it, by
// weftspun_studio's GallerySource proxy. Vite's default base ("/")
// makes the bundled entry script reference "/assets/index-*.js",
// root-absolute, which 404s once actually deployed under a prefix.
// Confirmed live with Playwright against the running proxy: the
// browser requested "/assets/index-*.js" instead of
// "/gallery/assets/index-*.js". Setting base fixes every asset URL
// Vite itself generates.
export default defineConfig({
  base: "/gallery/",

  build: {
    rollupOptions: {
      // index.html imports usd-viewer's own bundle by its final,
      // deployed path, "/gallery/vendor/usd-viewer/include.js", not
      // a relative one. The "vendor" npm script puts that exact
      // tree under public/vendor/usd-viewer/, so the absolute path
      // already resolves at runtime once served. Rollup does not
      // know that; it tries to bundle the import as a project
      // module and fails to find it on disk. Marking every
      // /gallery/ import external tells Rollup to leave the
      // reference alone and ship it as-is.
      external: (id) => id.startsWith("/gallery/"),
    },
  },
});
