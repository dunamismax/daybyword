// Day by Word's web app (BUILD.md D42, docs/decisions.md E36): SvelteKit 3 on
// the Node adapter, with Tailwind CSS 4 through its Vite plugin. SvelteKit 3
// takes its configuration here, in the sveltekit() plugin, not in
// svelte.config.js. Pages render on demand unless a route exports
// `prerender = true`; adapter-node writes a standalone server to build/.
import adapter from "@sveltejs/adapter-node";
import { sveltekit } from "@sveltejs/kit/vite";
import tailwindcss from "@tailwindcss/vite";
import { defineConfig } from "vite";

export default defineConfig({
  plugins: [
    tailwindcss(),
    sveltekit({
      // precompress writes .br and .gz beside each static asset; the Node
      // server serves them, and Caddy proxies to it (docs/deploy.md).
      adapter: adapter({ out: "build", precompress: true }),
    }),
  ],
  server: { host: "127.0.0.1", port: 5173, strictPort: true },
  preview: { host: "127.0.0.1", port: 4173, strictPort: true },
});
