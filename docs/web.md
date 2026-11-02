# Web implementation rules

**Target under D40 / Phase M (2026-11-02).** The current implementation is
still Hummingbird with CSS/vanilla modules in Server/Public. Phase M
replaces it with Next.js App Router, React, strict TypeScript, Tailwind
CSS and locally owned shadcn/ui components in apps/web. This guide governs
the replacement and all later web phases; docs/stack-migration.md maps the
legacy routes/components/tests. It does not claim the new files exist.

## Rendering and boundaries

- Use the Node runtime and `output: 'standalone'`. No Vercel-specific
  runtime, hosted data/auth, remote assets or CDN requirement.
- Public plan pages are semantic server-rendered HTML with truthful
  metadata. Client components own browser interaction and local storage;
  never read browser records during SSR or upload them just to render.
- All reading rules live in packages/reading-engine. Import that same
  pure TypeScript code for offline browser evaluation. Views, Route
  Handlers and SQL do not reimplement scheduling, coverage or progress.
- Next Route Handlers provide catalog delivery and later consented
  sync/auth. Validate request/response contracts; keep personal records out
  of URLs, logs and error messages. DB and secret modules are server-only.
- Version 1.0 keeps reading records in IndexedDB, not cookies or
  localStorage. localStorage is permitted for non-sensitive appearance
  preferences. No auth/session cookie is needed just to use the core.
- Use bounded requests, metadata-only logs, no-store for private responses
  and no shared/Cloudflare caching of personal responses. Offline code
  keeps approved catalog data and local events only.

## Styling and components

- Generate CSS custom properties and Tailwind theme/shadcn semantic
  variables from design/tokens.json, including light/dark/automatic and the
  existing reference-size preference. Do not import shadcn's default
  palette, remote fonts, icon pack or decorative assets.
- Reuse only the shadcn components the interface needs, checked into the
  project with their licenses. Audit their focus behavior and inline styles
  against the CSP. Keep accessible native elements for simple controls.
- Styles use Tailwind utilities and small local stylesheets where useful.
  No raw colors; rem-based text, 320 CSS px reflow, 200% text/400% zoom,
  visible keyboard focus and reduced-motion support. Preserve Morning.
- React Native uses its own controls with the generated tokens, not web
  shadcn components.

## CSP, assets and tooling

- Keep a strict same-origin production CSP without unsafe-inline or
  unsafe-eval. Next hydration/streaming uses per-request nonces and dynamic
  rendering as required by the pinned release. Put the matching nonce on
  the rendering request and response; verify errors and navigation too.
- Do not cache nonce-bearing rendered HTML as static/public pages. Do not
  weaken CSP to fix a shadcn primitive emitting forbidden inline styles;
  adapt/select the component and verify it under the built production app.
- A localhost-only development policy may allow documented tooling needs.
  Test the actual standalone production server separately.
- All images, fonts, scripts and styles are local; URLs opened by the
  reader may leave the site. Disable framework telemetry. Do not load
  analytics, tracking, model or third-party browser services.
- A single pinned workspace lockfile and formatter/linter/type checks
  replace the no-npm/no-bundler rules. Use typed shared English strings,
  named exports, two-space indentation, UTF-8 and final newlines.
- Copy public and .next/static into the standalone image and trace
  workspace packages/catalog data. Test real image assets, not only dev.

## Shell, routes and support

Preserve the skip link, header wordmark and Today/Plans/Progress/Settings
navigation, aria-current, one main and heading, footer independence
statement, custom 404 and every stable route in docs/urls.md.
Keep /dev/components and test date overrides out of production.
Keep /up no-store and informative only about readiness.

D30 still targets current/previous Safari, Chrome, Firefox and Edge on
desktop/mobile. Port the unsupported-browser and noscript notices without
crashing the notice itself; public server-rendered content remains usable.
Port the current tour's route/theme/settings/focus/overflow assertions to
the new browser harness, and check CSP/console under standalone output.
Retain print CSS and service-worker paths across upgrades; offline caches
must have versioning, cleanup, no cross-reader data and no stale private SSR.
