// Builds the browser parity page (docs/engine.md, "Parity") into
// web/build/parity-browser/; scripts/domain-browser.ts serves it.
import { defineConfig } from "vite";

export default defineConfig({
  root: import.meta.dirname,
  base: "./",
  logLevel: "warn",
  build: { outDir: "../../build/parity-browser", emptyOutDir: true },
});
