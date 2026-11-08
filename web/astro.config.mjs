// Day by Word's web app (BUILD.md PM.13, decisions E33 and E34).
// Server output on the Node standalone adapter: pages and endpoints render
// on demand unless they export `prerender = true`. PM.16 ports the pages.
import node from "@astrojs/node";
import { defineConfig } from "astro/config";

export default defineConfig({
  site: "https://daybyword.com",
  output: "server",
  adapter: node({ mode: "standalone" }),
  trailingSlash: "never",
  // No server sessions: at 1.0 the server keeps no reader data (D10, D39).
  session: false,
  // No phone-home or injected development scripts (AGENTS.md §5).
  devToolbar: { enabled: false },
  server: { host: "127.0.0.1", port: 4321 },
});
