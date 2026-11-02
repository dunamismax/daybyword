# Astro web rules

**D41/E33 target; implementation still Hummingbird until Phase M.**
Build web/ with Astro/TypeScript and @astrojs/node standalone for runtime
Actions, API endpoints and PostgreSQL. Prerender static public content as
appropriate; do not deploy only static files when APIs are needed.

- Keep semantic Astro layouts/pages, stable routes, skip link, one main,
  headings, aria-current and independence footer from docs/urls.md.
- Use Actions for validated forms/server logic and src/pages/api/v1 for
  Swift/client APIs. Server-only Drizzle/Postgres imports never enter
  browser or native bundles. Validate inputs, origin/CSRF and request size.
- Hydrate React islands only for real interaction. Tailwind/shadcn are
  available where useful, not mandatory frameworks for every page.
  No new imagery or generic palette; preserve Morning and design tokens.
- TypeScript domain logic follows docs/engine.md and the same JSON cases
  as native Swift. Do not reimplement reading rules in pages, islands,
  Actions or SQL. E33 records the cross-language parity requirement.
- At 1.0 progress remains in IndexedDB; server computation is transient
  from request bodies and retains nothing. No records in URLs, cookies,
  logs or shared caches. Native/browsers never connect to Postgres.
- Preserve cached upcoming plans/readings and offline marks with stable
  ids, cache-version upgrades and honest offline status. Local browser
  computation, when necessary, imports the domain module.
- Generate CSS/Tailwind/shadcn variables from design/tokens.json; no raw
  colors, remote fonts/scripts/styles/images or CDN code. Localizable
  strings, English first, two-space indentation and pinned lint/type rules.
- Strict production CSP with no unsafe-inline/eval. Verify the actual
  production Astro output and island/component style behavior; do not
  blindly copy Next-specific nonce/cache configuration. Choose/adapt UI
  components rather than weaken policy silently.
- Keep metadata-only app/proxy logs, disable framework/tool telemetry and
  use no-store for private responses. No AI/model/analytics SDKs.
- D30 browsers, keyboard/focus/Reduce Motion, light/dark, 320px reflow,
  200% text and 400% zoom remain required. Public SSR content and plain
  unsupported/noscript notices remain usable without client hydration.
- Port every existing web tour assertion before retiring Swift web tools.
  Test Node standalone image, route/error/health behavior, Actions and
  hydration in a real browser, not only the development server.

Existing Server/Public and Server/Sources/DayByWordWeb are the porting
oracle. After parity update the code pointers and make serve command;
preserve /assets URLs or explicit redirects. React is web-only; native
SwiftUI stays independent of DOM components.
