import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react-swc'

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    setupFiles: ['./tests/setup.js'],
    globals: true,
    css: true,
    // Playwright owns tests/e2e, and `npm run test:e2e` runs it. The
    // default include pattern matches `.spec.js` too, so vitest
    // collected those specs and failed on them. They were never
    // broken. The wrong runner ran them.
    exclude: ['**/node_modules/**', '**/dist/**', 'tests/e2e/**'],
  },
  resolve: {
    alias: {
      buffer: 'buffer/'
    }
  }
})