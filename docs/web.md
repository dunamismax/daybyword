# SvelteKit web rules

**D42/E36.** `web/` is a SvelteKit 3 workspace (Svelte 5, TypeScript,
Tailwind CSS 4) built by @sveltejs/adapter-node into a standalone Node
server behind the host's Caddy, with PostgreSQL 18 through Drizzle. It
serves every page; the Swift server it replaced is gone (PM.20).
Prerender static public content as appropriate; do not deploy only static
files when APIs are needed.

- Configuration is the `sveltekit()` plugin in `web/vite.config.ts`;
  SvelteKit 3 reads no svelte.config.js.
- Keep semantic layouts and pages (`+layout.svelte`, `+page.svelte`),
  stable routes, skip link, one main, headings, aria-current and the
  independence footer from docs/urls.md.
- Use form actions (`+page.server.ts`) for validated forms, with
  progressive enhancement so a form works before hydration, and
  `src/routes/api/v1/**/+server.ts` for Swift and browser APIs.
  Server-only Drizzle/PostgreSQL code lives in `src/lib/server/`, which
  SvelteKit never bundles for the browser; nothing there enters native
  bundles either. Validate inputs, origin and
  request size (`BODY_SIZE_LIMIT`); the public origin is `paths.origin` or
  Caddy's Host header (SvelteKit 3 removed adapter-node's `ORIGIN`).
- Svelte 5 components render every page on the server. No page loads
  SvelteKit's client runtime yet (`csr = false` in the root layout, E38):
  its route announcer writes an inline style the strict CSP refuses. The
  little interaction there is (Settings, copy buttons, the print button,
  the old-browser notice, and since P8.10c Today, starting a plan, and
  export and deletion) is small same-origin modules in `static/assets/`;
  E38 lists the ways to bring Svelte interaction back without weakening
  the policy. `reading.js` keeps the reader's journal in IndexedDB and
  sends it to `/api/v1/today` and `/api/v1/events`, which fold it with the
  served catalog through the domain module, answer (Today's cards as
  HTML rendered by a Svelte component, or new events in their wire form)
  and keep nothing (E52). The script holds no reading rule and no
  interface words: it reads its messages from the page's data attributes. No component kit is
  required; no new imagery or generic palette; preserve Morning.
- TypeScript domain logic lives in `src/lib/domain/`, follows
  docs/engine.md and the same JSON cases as native Swift. Do not
  reimplement reading rules in components, load functions, form actions
  or SQL. E33 records the cross-language parity requirement.
- The catalog is read on the server, from PostgreSQL, as the read-only web
  role (`src/lib/server/catalog/read.ts`): once per import, kept in
  memory, with one small query a request to see which import is current.
  `present.ts` beside it turns a plan into what its pages show: the
  compiler's facts, the domain module's workload and sample week (the
  engine's days ahead for a candidate enrollment), and words from the
  string table. A plan's own words (title, summary, limitations and the
  rest) are the catalog's and are shown as written. With no
  `DATABASE_URL` there is no catalog: Plans is empty and a plan's
  address is not found.
- **Paper.** `@media print` in `app.css` drops the header, footer,
  forms and buttons, and tokens.css switches to Morning's light colors
  whatever the screen's appearance, so a week's checklist
  (`/plans/<id>/week`) prints as the page alone.
- `scripts/with-catalog.sh COMMAND` runs a command with a throwaway
  PostgreSQL holding the roles, the migrations and the release catalog,
  as a deploy leaves them. `make serve-web`, the production tests and the
  web tour run inside it, so local pages come through the same code as
  the live ones.
- At 1.0 progress remains in IndexedDB; server computation is transient
  from request bodies and retains nothing. No records in URLs, cookies,
  logs or shared caches. Native apps and browsers never connect to Postgres.
- Offline (E53): the service worker (`src/service-worker/index.ts`,
  registered by `reading.js`) keeps each release's files and the pages
  Today, Progress and Settings; Today keeps seven days of cards in
  `localStorage`; marks made offline wait in IndexedDB with their own ids
  and are sent when there is a connection. Local browser computation,
  when it becomes necessary, imports the domain module.
- Tailwind CSS 4 is the styling layer, with one entry at `src/app.css`.
  Generate its `@theme` variables from design/tokens.json; no raw colors,
  remote fonts/scripts/styles/images or CDN code. Localizable strings,
  English first, two-space indentation and pinned lint/type rules
  (eslint with eslint-plugin-svelte, prettier with the svelte and
  tailwind plugins, svelte-check failing on warnings).
- Strict production CSP with no unsafe-inline/eval, set through
  SvelteKit's `csp` option (hashes in prerendered pages, nonces in
  rendered ones). Verify it against the actual adapter-node build,
  including hydration and any Svelte transition that writes inline
  styles; change the component rather than weaken the policy.
- Keep metadata-only app/proxy logs and use no-store for private
  responses. SvelteKit, Vite and Tailwind send no telemetry; add no tool
  that does. No AI/model/analytics SDKs.
- D30 browsers, keyboard/focus/Reduce Motion, light/dark, 320px reflow,
  200% text and 400% zoom remain required. Public server-rendered content
  and plain unsupported/noscript notices remain usable without hydration.
- Test the production server (`node server.ts` around the adapter-node
  build; `make serve-web`, `make smoke-web`), route/error/health
  behavior, form actions and hydration in a real browser, not only the
  development server.

The checks the retired Swift server's tests made now live in
`web/test/` (PM.20): the address contract (tests/fixtures/routes.json),
the shell every page shares, Settings, the configuration, and that pages
show only words from the string table (`src/lib/strings.ts`) and the
catalog. A table entry is never a bare placeholder, which would let any
words pass, and a plan's page keeps table text and catalog text in
separate elements so each can be checked. Preserve
/assets URLs or explicit redirects. Svelte components are web-only;
native SwiftUI stays independent of them.
