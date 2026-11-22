// Day by Word's web app (BUILD.md D42, docs/decisions.md E36): SvelteKit 3 on
// the Node adapter, with Tailwind CSS 4 through its Vite plugin. SvelteKit 3
// takes its configuration here, in the sveltekit() plugin, not in
// svelte.config.js. Pages render on demand unless a route exports
// `prerender = true`; adapter-node writes a standalone server to build/,
// which server.ts wraps with the headers every response carries.
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
      // /assets/reading.js registers src/service-worker.ts itself (P8.11),
      // as no page loads SvelteKit's client runtime (E38).
      serviceWorker: { register: false },
      // Absolute asset paths (/_app/…): the service worker shows the kept
      // offline page in place of any page it never kept (P15.2), and a
      // relative path would then point below that page's address. The site
      // has no base path, so nothing is lost.
      paths: { relative: false },
      // The strict policy (docs/decisions.md E11, E36): nothing from another
      // host, no inline script or style. SvelteKit adds a nonce (or, on a
      // prerendered page, a hash) for the scripts it writes itself; server.ts
      // sends the same policy, without one, on everything else.
      csp: {
        mode: "auto",
        directives: {
          "default-src": ["none"],
          "script-src": ["self"],
          "style-src": ["self"],
          "img-src": ["self"],
          "font-src": ["self"],
          "connect-src": ["self"],
          "manifest-src": ["self"],
          "worker-src": ["self"],
          "form-action": ["self"],
          "base-uri": ["none"],
          "frame-ancestors": ["none"],
        },
      },
    }),
  ],
  server: { host: "127.0.0.1", port: 5173, strictPort: true },
  preview: { host: "127.0.0.1", port: 4173, strictPort: true },
});
