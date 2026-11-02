# Final stack alignment

**D41, 2026-11-02. Planned only.** Astro + PostgreSQL/Drizzle is final.
Swift/Python are used only when this project needs them. The existing
iPhone/iPad app needs Swift; no Python application is required.
D40's Next/Expo proposal and PM.1–PM.11 are withdrawn before implementation.
Phase M now starts at PM.12 and precedes all feature work.

## What remains and what changes

| Area | Existing baseline | Final target |
|---|---|---|
| Web | Hummingbird HTML/CSS/vanilla modules | Astro/TypeScript, Node standalone, public prerendering where useful |
| Interactivity | Small web modules | Astro scripts/Actions/API endpoints; React islands only where needed |
| Styling | Morning tokens and CSS | Preserve tokens; Tailwind/shadcn optional per UI need |
| Server data | Read-only Catalog.sqlite, schema 3 | PostgreSQL, server-only Drizzle schema/migrations, validated catalog import |
| Apple app | SwiftUI/Observation, widgets/intents shell | Retain; no Expo or framework rewrite |
| Local native data | ReadingData/system SQLite | Retain for offline/native catalog; no client Postgres connection |
| Reading logic | Swift ReadingEngine | Swift native + pure TypeScript web, one spec and mandatory shared parity cases (E33) |
| Compiler | Swift CatalogCompiler, rights/claims checks | Retain needed domain/compiler code; define deterministic server export/import |
| General tools | Make/shell/Swift helpers | Keep justified working tools; Python only if a task needs it, using uv/ruff |
| Deployment | make deploy is unimplemented | Project Compose Astro/Postgres behind host Caddy/Cloudflare |
| Backups | Not provisioned here | Nightly pg_dump, encrypted off-server copy, tested restore; no Litestream |
| Accounts | Deferred after 1.0 | Better Auth inside Astro with Drizzle/Postgres when Phase 14 opens |
| Other targets | iPhone/iPad exist; Mac later | SwiftUI multiplatform only when native desktop is actually needed |
| Excluded | No Bible text/AI/analytics | Same; no model SDK, mandatory Python, Next, Expo or Tauri |

Astro static output suits pure content sites, but Day by Word needs API
compute/catalog services. Select @astrojs/node standalone with server
output, prerender public pages that do not require runtime work, and
keep endpoints/Actions on demand. Do not replace the whole product with a
single React island without a demonstrated need. No hosted services are
required to run Astro/Postgres.

## Inspected inventory and preservation

Runtime source is unchanged from 97c3981; 12fa06a and 11deb74 changed docs
only. Baseline make check passed: 54 engine, 7 data, 30 compiler, 31 server,
15 app tests and 63 string keys. No live deployment or App Store Connect
inspection occurred here. Prior reports of TestFlight build 25 and no
deployment must be verified at PM.12.

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
  styles/modules and artwork. Port to web/src/pages, layouts/components,
  actions and pages/api/v1; preserve asset URLs or redirects.
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

## Target layout

~~~text
web/                         Astro project; pinned package.json/lockfile
web/src/pages/               public pages and api/v1 endpoints
web/src/actions/             validated forms/server actions
web/src/domain/              TypeScript reading logic, no UI/DB imports
web/src/db/                  server-only Drizzle pg schema/client
web/drizzle/                 reviewed SQL migrations and metadata
tests/fixtures/              shared Swift/TypeScript semantic cases
Packages/ apple/ catalog/    retained needed native/domain/compiler/source code
deploy/                      Compose, Dockerfile, Caddy site and scripts
tools/                       only if additional utilities are actually needed
~~~

Pin compatible supported Astro/Node/npm/Drizzle/pg and optional UI/test
dependencies at PM.13. No floating production images or framework
telemetry. Keep Swift checks until their owning targets are retired,
which does not include the retained Apple app.

## Engine and catalog contracts

The stack now spans Swift and TypeScript. E33 explicitly replaces the
literal single-language engine rule: one specification, two domain
modules, shared golden JSON inputs/outputs, no rules copied into views,
Actions, SQL or reports. Extract existing Swift oracles before porting.
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

No persistent reader data at 1.0. Astro can evaluate transient request-body
records and discard them with no body logging; Swift computes locally.
The web caches upcoming readings and keeps offline marks/ids in IndexedDB.
If local browser evaluation is needed, use the same TypeScript module,
not ad hoc island logic. Define cache/version upgrades and honest offline
status. Future sync needs explicit consent and authenticated Astro APIs.

## Qualification and later work

Port every route/settings/component/string assertion before retiring the
Swift web tests. Verify built standalone output behind the intended
proxy, CSP, asset loads and any island hydration, not only the dev server.
Preserve WCAG/keyboard/320px/zoom/light/dark and native AX5/VoiceOver/
Reduce Motion/offline behavior. No Next-specific nonce/cache assumptions
should be copied without checking Astro's actual production output.

make check must cover retained Swift, Astro lint/types/build/tests,
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

Checked for planning on 2026-11-02; recheck when pinning implementation.
[Astro Node standalone](https://docs.astro.build/en/guides/integrations-guide/node/),
[on-demand/prerendering](https://docs.astro.build/en/guides/on-demand-rendering/),
[Actions](https://docs.astro.build/en/guides/actions/),
[React islands](https://docs.astro.build/en/guides/framework-components/),
[Drizzle PostgreSQL](https://orm.drizzle.team/docs/get-started-postgresql),
[Drizzle migrations](https://orm.drizzle.team/docs/migrations) and
[pg_dump](https://www.postgresql.org/docs/current/app-pgdump.html).
