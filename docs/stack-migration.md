# Final stack alignment

**Finished 2026-11-20 (PM.20).** This is the record of Phase M: what was
kept, what was replaced, and the evidence. The stack is SvelteKit 3 ·
Svelte 5 · TypeScript · Tailwind CSS 4 · PostgreSQL 18 + Drizzle ORM · Node
(adapter-node) · Caddy (D42, replacing D41's Astro web; E33 and E36).
SvelteKit in `web/` serves every page, and the Swift/Hummingbird server
it replaced is removed. The native iPhone and iPad app stays Swift; no
Python application is required. For current rules read AGENTS.md §5,
docs/web.md and docs/engine.md; the sections below are kept as written
during the migration.

## What remains and what changes

| Area | Existing baseline | Final target |
|---|---|---|
| Web | Hummingbird HTML/CSS/vanilla modules | SvelteKit 3/Svelte 5/TypeScript on adapter-node, public prerendering where useful |
| Interactivity | Small web modules | Svelte 5 components, form actions and `/api/v1` endpoints; `csr = false` where none is needed |
| Styling | Morning tokens and CSS | Tailwind CSS 4 with Morning's tokens as theme variables; no component kit |
| Server data | Read-only Catalog.sqlite, schema 3 | PostgreSQL 18, server-only Drizzle schema/migrations, validated catalog import |
| Apple app | SwiftUI/Observation, widgets/intents shell | Retain; no Expo or framework rewrite |
| Local native data | ReadingData/system SQLite | Retain for offline/native catalog; no client Postgres connection |
| Reading logic | Swift ReadingEngine | Swift native + pure TypeScript web, one spec and mandatory shared parity cases (E33) |
| Compiler | Swift CatalogCompiler, rights/claims checks | Retain needed domain/compiler code; define deterministic server export/import |
| General tools | Make/shell/Swift helpers | Keep justified working tools; Python only if a task needs it, using uv/ruff |
| Deployment | make deploy is unimplemented | Project Compose adapter-node/PostgreSQL 18 behind host Caddy (DNS-only Cloudflare records) |
| Backups | Not provisioned here | Nightly pg_dump, encrypted off-server copy, tested restore; no Litestream |
| Accounts | Deferred after 1.0 | Better Auth inside SvelteKit with Drizzle/Postgres when Phase 14 opens |
| Other targets | iPhone/iPad exist; Mac later | SwiftUI multiplatform only when native desktop is actually needed |
| Excluded | No Bible text/AI/analytics | Same; no model SDK, mandatory Python, Next, Astro, React, Expo or Tauri |

A static build suits pure content sites, but Day by Word needs API
compute/catalog services. Use @sveltejs/adapter-node, prerender public
pages that need no runtime work (`export const prerender = true`), and
keep endpoints and form actions on demand. Ship client JavaScript only to
pages that need it (`csr = false` elsewhere). No hosted services are
required to run SvelteKit/PostgreSQL.

## Inspected inventory and preservation

Runtime source is unchanged from 97c3981; 12fa06a and 11deb74 changed docs
only. The recorded baseline is the next section.

- Packages/ReadingEngine contains BookID/BookRegistry, Versification,
  Passage/Reading, ReferenceFormat/Formatter, VerseSet, WordCounts,
  Workload/PlanWorkload, PlanID and Plan. ReadingEngine.specificationVersion
  is 0: scheduling/journal/reminders are not implemented.
- Packages/ReadingData holds a SQLite wrapper and catalog metadata/reader;
  no journal or sync client yet. Catalog schema is 3.
- Packages/CatalogCompiler contains PlanFile, SourcesRegistry, PlanFacts,
  CatalogBuild and SHA256 plus the CLI. It validates references, rights,
  review levels and claims, and replaces output atomically.
- catalog/plans is empty. Preserve catalog/scripture numeric data,
  catalog/SOURCES.md, all rights/review rules and the original source
  grammar. Do not create production plans as migration fixtures.
- Server/Sources/DayByWordWeb holds routing, shell/components, Strings,
  settings, security and metadata-only logging. Server/Public holds
  styles/modules and artwork. Port to web/src/routes (+layout.svelte,
  +page.svelte, +page.server.ts with form actions) and
  src/routes/api/v1; preserve asset URLs or redirects.
- apple/App, Shared, Widgets and their tests remain native. Preserve
  Localizable.xcstrings, tokens, VoiceOver labels, reference sizes and
  scene navigation. Existing preferences are appearance/referenceSize in
  UserDefaults and navigation in SceneStorage.
- .swift-version pins 6.4.2; Swift 6 complete concurrency, @Observable,
  Xcode 27/iOS 27 SDK and iOS/iPadOS 26 minimum remain. Existing
  make run, make test-app and make tour-app provide build/test access;
  scripts/sim-destination.sh chooses the simulator. Keep XcodeGen as the
  project generator. SwiftData/GRDB are not required replacements.
- Keep com.daybyword.app, extension suffix, group.com.daybyword.app,
  daybyword://, App Store record and increasing build numbers. Never
  uninstall to claim upgrade preservation.
- Keep Morning, D39's eight-plan 1.0 scope, neutral voice, no-account/
  offline privacy and all existing stable URLs. No SOUL.md or other-project
  code/content. BUILD-HISTORY remains untouched.

## Baseline (PM.12, 2026-11-02)

Recorded before anything is replaced; later items compare against it.

- **Commit** 50ee64c on main, equal to origin/main after `git pull
  --ff-only`, and to Codeberg's main (`git ls-remote`), so the mirror was
  in sync. `make check` passed with zero warnings: 54 engine, 7 data, 30
  compiler, 31 server and 15 app tests, 63 app string keys.
- **Toolchain:** Swift 6.4.2, Xcode 27.2 (27B52). Node 26.13.0 and npm
  11.20.0 are installed but nothing pins them yet (PM.13).
- **Catalog:** schema 3, development build, 0 plans; content_sha256
  `ac986b77…1a6d`. Its `scripture` table holds books.json and the English
  versification; word counts reach the catalog only as plan facts.
- **App data:** the simulator `scripts/sim-destination.sh` picks (iPhone 18
  Pro) holds `com.daybyword.app` with saved scene state and launch
  snapshots only: no preferences written (every setting at its default), no
  App Group container, no database. No physical device was inspected. Local
  data at baseline is UserDefaults `appearance` and `referenceSize` and
  SceneStorage `navigation`, nothing else.
- **Signing and TestFlight:** one Apple Development identity (the owner's)
  in the keychain. `apple/Config/Secrets.xcconfig` is absent from this
  checkout, so `make archive` needs it recreated from the example first.
  Xcode's archives hold `com.daybyword.app` 0.1.0 (25) from 2026-11-01;
  that the upload reached App Store Connect was not checked (it needs the
  owner's sign-in).
- **Live deployment:** none. daybyword.com and www resolve to the host
  directly (not proxied) and the TLS handshake fails, since no site serves
  the name. On ubuntu-vm (read-only look) there is no
  `/srv/www/daybyword.com` and no Caddy site file for it; 127.0.0.1:4316
  and :4321 are free. The host already runs a PostgreSQL on 127.0.0.1:5432
  and another project's container on a loopback port, so this project's
  database must stay on its private Docker network. No shared deploy lock
  was found under `/run/lock`; P7.1 must find the real one.
- **Fixtures:** [tests/fixtures/](../tests/fixtures/README.md) captures
  references (87 inputs, 53 invalid), coverage, workload, scripture
  totals (1,189 chapters, 31,102 verses, 754,449 words for the 66 books),
  plan ids, 45 invented plan files (39 refused), 34 web addresses, the
  security headers, 64 web strings and the device settings. Swift tests
  check every one.
- **Behaviour decided in PM.16 (E38):** `/today/` now redirects (308) to
  `/today`; assets are cached (fingerprinted files a year, the site's own
  files an hour, pages `no-cache`); a missing asset still gets the HTML
  "Page not found" page; `/api/v1/…` answers a JSON 404 until an endpoint
  claims it.

## The native app, verified (PM.17, 2026-11-20)

- **Toolchain:** Swift 6.4.2 and Xcode 27.2 as pinned; `make check` builds
  the app, the widget extension and the packages with zero warnings and
  passes the app's unit tests and String Catalog check.
- **Identity:** `com.daybyword.app` 0.1.0, its widget extension
  `com.daybyword.app.widgets` (`com.apple.widgetkit-extension`) embedded
  and registered with the system (pluginkit), `daybyword://`, and the
  bundled read-only `Catalog.sqlite`. No App Group or entitlements exist
  yet; P12.1 adds `group.com.daybyword.app`.
- **Upgrade keeps the reader's settings:** on the iPhone 18 Pro simulator,
  appearance Dark and reference size Largest were written to the installed
  build's UserDefaults, the current build was installed over it (no
  uninstall), and the app opened in Dark with Largest selected while the
  simulator was in light mode. The test values were then removed.
- **Widget:** the placeholder Next reading widget renders in the system
  widget gallery. There are no App Intents yet (P8.9, P12.4), and no
  native offline store beyond the bundled catalog and UserDefaults
  (journal: P5.4).
- **No API adapters added:** the app makes no network calls at this stage,
  so there is nothing to adapt; native code never reaches PostgreSQL.
- **Scripts audited, all kept:** `tokens.swift`, `strings.swift`,
  `versification.swift` and `wordcounts.swift` generate or check
  committed data; `xcodebuild.sh`, `run-app.sh`, `sim-destination.sh`,
  `archive.sh` and `testflight.sh` drive the app; `test-linux.sh` and
  `linux/` test the Swift packages on Linux; `check-*.sh`,
  `with-postgres.sh`, `db-drift.sh` and `web-smoke.sh` are gates;
  `webtour.swift` tours the Swift site until PM.19/PM.20 port its
  assertions. Each works and serves a current need, so none is converted,
  and no Python is introduced.
- Not done: no physical device, no iPad run, no TestFlight upload (build
  25's upload is still unverified).

## Parity, qualified (PM.19, 2026-11-20)

What was run, and what it showed. Nothing here claims scheduling, a
journal, sync or reminders, which do not exist yet.

| Area | Evidence |
|---|---|
| Golden fixtures | All 190 engine cases pass in Swift, Node and headless Firefox 159 (PM.15); strings, settings and every routes.json case pass against the SvelteKit production server, with E38's four recorded differences (PM.16) |
| Real PostgreSQL | `make test-db` on PostgreSQL 18.6: fresh and repeated migrations, atomic and racing imports, refusals, rollback, grants, readiness (PM.14, PM.18) |
| Production image | `make rehearse-deploy`: the Docker image under Compose with a private database, candidate and live `check-live`, backup, isolated restore, redeploy, rollback (PM.18) |
| API isolation | `/api/v1/…` is a JSON 404 with `no-store`; PostgreSQL has no host port and sits on an internal network; the web role is refused writes; no database code or credentials reach a browser bundle (`src/lib/server/`) or the app |
| Import retries | Re-importing the same catalog is a no-op (`already-current`), in `make test-db` and in the rehearsal's second deploy |
| Web tour | `make tour-web` now tours the SvelteKit production server: 275 checks in Firefox at 1280 and 500 px in light and dark (headings, current section, no sideways scroll, notice hidden, footer, skip link first, Settings applied and kept). The same semantic tour passes on the Swift server (`DBW_TOUR_SERVER=swift`) |
| Phone and 200% text | Checked in the desktop app's built-in browser: 375 px with no sideways scroll, 200% text at 640 px with no sideways scroll, dark, skip link, Settings, copy fallback, console clean (PM.16) |
| Native | `make tour-app` in light, dark and now light at AX5 (labels wrap, nothing cut off); `make test-ui` passes, including references and statuses read naturally by VoiceOver; settings kept across an in-place install (PM.17) |
| Linux | `make test-linux` passed for the Swift packages and server |

**Differences found and settled:** E38's four (trailing-slash redirect,
the stylesheets folded into one fingerprinted file, the favicon's type,
`/api/v1` JSON 404); and Tailwind's reset removing paragraph spacing,
restored in `web/src/app.css` after the tour's screenshots showed it.

**Not run:** the web tour in Safari (needs "Allow remote automation", a
setting agents do not change) or Chrome; a screen reader on the web;
offline behavior, since neither the web's offline mode (P8.11) nor any
network use in the app exists yet; a physical device or iPad.

## Target layout

~~~text
web/                         SvelteKit project; pinned package.json/lockfile
web/vite.config.ts           SvelteKit (adapter-node) and Tailwind plugins
web/src/routes/              pages, form actions, api/v1 endpoints, /up
web/src/app.css              Tailwind CSS 4 entry, Morning theme variables
web/src/lib/domain/          TypeScript reading logic, no UI/DB imports
web/src/lib/server/          server-only Drizzle schema/client, catalog import
web/scripts/                 one-shot migration and catalog-import jobs
web/drizzle/                 reviewed SQL migrations and metadata
tests/fixtures/              shared Swift/TypeScript semantic cases
Packages/ apple/ catalog/    retained needed native/domain/compiler/source code
deploy/                      Compose, Dockerfile, Caddy site and scripts
tools/                       only if additional utilities are actually needed
~~~

PM.13 (2026-11-08) created `web/` with pinned Node/npm and its lint,
type, test, and production-build gates (E34), on Astro; PM.14 pinned
Drizzle/pg; PM.21 (2026-11-20) replaced Astro with SvelteKit 3, Svelte 5
and Tailwind CSS 4 and moved PostgreSQL to 18 under the same gates (E36). No floating production images or framework
telemetry. Keep Swift checks until their owning targets are retired,
which does not include the retained Apple app.

## Engine and catalog contracts

The stack now spans Swift and TypeScript. E33 explicitly replaces the
literal single-language engine rule: one specification, two domain
modules, shared golden JSON inputs/outputs, no rules copied into views,
form actions, SQL or reports. Extract existing Swift oracles before porting.
P5.1 writes the unbuilt scheduling specification; PM.15 ports only
already implemented references/counts/workload and defines the boundary.
Every later P5 rule lands in both runtimes with parity before completion.

Preserve 78 registered books, canonical ids/orders/names, non-1 starting
verse/chapter ranges, strict reference serialization, one-chapter display,
1,189 chapters/31,102 verses for the 66 books, 754,449 WEB words, E31
doxology/footnote rules, 238/183 wpm and rounding. Test invalid inputs,
omissions, repeats and empty sets. No Scripture text enters fixtures.

The compiler remains the rights/coverage gate. Define a deterministic
versioned transport export, including scripture resources and offline
numeric facts, and compare normalized schema-3 data, not SQLite file bytes.
Map catalog_meta, plans, assignments, plan_facts and scripture into
Drizzle tables. Server plans use immutable (id, version) keys; assignments
include plan version and unique positions. Keep native read-only catalogs
rebuildable, separate from personal records and mutable server DB.

Generate/review/commit SQL; migrate once under deploy lock, not from every
request. Import only release-cleared/reviewed compiler output in one
idempotent transaction by digest. Test empty/repeated/failed imports,
fresh/upgrade SQL and incompatible schema handling. Do not expose DB
credentials or the DB package to native/browser bundles.

No persistent reader data at 1.0. SvelteKit endpoints can evaluate transient request-body
records and discard them with no body logging; Swift computes locally.
The web caches upcoming readings and keeps offline marks/ids in IndexedDB.
If local browser evaluation is needed, use the same TypeScript module,
not ad hoc component logic. Define cache/version upgrades and honest offline
status. Future sync needs explicit consent and authenticated SvelteKit APIs.

## Qualification and later work

Port every route/settings/component/string assertion before retiring the
Swift web tests. Verify built standalone output behind the intended
proxy, CSP, asset loads and hydration, not only the dev server.
Preserve WCAG/keyboard/320px/zoom/light/dark and native AX5/VoiceOver/
Reduce Motion/offline behavior. No Next-specific nonce/cache assumptions
should be copied without checking SvelteKit's actual adapter-node output.

make check must cover retained Swift, SvelteKit lint/svelte-check/build/tests,
catalog integrity and real Postgres/parity tests. check-full adds browser
and native tours plus Linux. Manual CI stays D31. Keep signing credentials
private and app release commands working; no native rewrite is required.

Use Python only for a demonstrated utility need. If introduced, use uv
and ruff; inline dependencies or a locked project as appropriate, and
Typer/httpx/Pydantic only where needed. A Python maintenance job connects
to Postgres through a restricted driver, not a SQLite server file.
Use systemd timers for recurring jobs. Do not add a Python backend,
duplicate engine or rewrite all Swift scripts just to add a language.

PM.18 rehearses deploy/backup/restore locally; P7 performs host
provisioning/cutover under D34. See docs/deploy.md. After PM.20, remove
Hummingbird/server-only legacy artifacts, retain needed native packages,
update owning docs and proceed to P5.1. Do not tick features that do not
exist.

## Documentation references

Checked on 2026-11-20 for the pinned versions in E36; recheck when upgrading.
[Migrating to SvelteKit 3](https://svelte.dev/docs/kit/migrating-to-sveltekit-3),
[adapter-node](https://svelte.dev/docs/kit/adapter-node),
[page options and prerendering](https://svelte.dev/docs/kit/page-options),
[form actions](https://svelte.dev/docs/kit/form-actions),
[Tailwind CSS with SvelteKit](https://tailwindcss.com/docs/installation/framework-guides/sveltekit),
[Drizzle PostgreSQL](https://orm.drizzle.team/docs/get-started-postgresql),
[Drizzle migrations](https://orm.drizzle.team/docs/migrations) and
[pg_dump](https://www.postgresql.org/docs/current/app-pgdump.html).
