# Unified-stack rewrite

**Status: approved plan, 2026-11-02; implementation has not started.**
BUILD.md D40 supersedes the old stack. Phase M comes before every existing
phase. This review changed documentation only: no application code,
dependencies, database, signing configuration, or server was changed.

## Scope and order

Rewrite the existing foundation completely before P5.1. Port what exists;
do not build the unfinished scheduling, enrollment, journal, reminders,
accounts, or launch catalog under the guise of migration. Those retain
their existing item ids. Historical completed phases remain evidence of the
Swift foundation, not proof that their replacements pass.

Preserve Morning (D18), the product rules, rights and editorial gates,
stable addresses, app identity, privacy, offline operation, and the eight
original-plan scope of D39. No Bible text, analytics, or AI features.
The owner requested only the parts of the common stack this project needs.

| Component | Decision |
|---|---|
| Web and API | Next.js App Router, React, strict TypeScript; Node runtime; `output: 'standalone'`; no Vercel services or Edge-runtime dependency |
| Web UI | Tailwind CSS and locally owned shadcn/ui components, mapped to Morning tokens; no default shadcn redesign |
| Server data | PostgreSQL through Drizzle; a project database and restricted role; initially public catalog and migration metadata only |
| iPhone/iPad | Expo / React Native, local development and release builds; retain iOS/iPadOS 26 minimum and validate the selected SDK |
| Offline data | expo-sqlite on mobile, IndexedDB on the web; these are device stores, never connections to server PostgreSQL |
| Logic | One platform-neutral TypeScript reading engine, imported by Next.js, Expo, browser offline code, and the catalog compiler |
| Deployment | Docker Compose, immutable standalone Node image and project Postgres service, host Caddy, Cloudflare TLS |
| Accounts | Better Auth with its Drizzle/Postgres adapter, deferred to Phase 14; preserve optional passkeys and recovery requirements, no hosted auth |
| Billing | Stripe only if later pricing work requires it; no integration in this rewrite |
| LLMs | Omit the Vercel AI SDK and model providers: D23 forbids AI features |
| Desktop / Android | No new release target now. Tauri if a desktop app is justified later; Expo for Android when D6 opens |

## Verified starting point

Reviewed at `97c3981` on main, 2026-11-02. The working tree was clean and
`git pull --ff-only` was current. The initial package tests passed: 54
ReadingEngine, 7 ReadingData, 30 CatalogCompiler, 31 server tests. The
whole `make check` result is recorded in BUILD.md's Handoff notes.
No live server or App Store Connect inspection was performed in this review.
The prior handoff reports TestFlight build 25 and no deployment; verify
both before any replacement upload or cutover.

| Existing source | What actually exists | Replacement |
|---|---|---|
| `Packages/ReadingEngine/Sources/ReadingEngine/` and its tests | BookID, BookRegistry, Versification, Passage/Reading, strict ReferenceFormat, ReferenceFormatter, VerseSet, WordCounts, Workload/PlanWorkload, PlanID, Plan | `packages/reading-engine/`, same behaviors and test vectors |
| `ReadingEngine.swift` | Only `specificationVersion = 0`; no scheduling engine | Keep scheduling open in P5; do not claim it is ported |
| `Packages/CatalogCompiler/` | PlanFile, SourcesRegistry, PlanFacts, CatalogBuild, SHA256, CLI; schema 3; atomic output and release filters | `packages/catalog-compiler/` TypeScript CLI and deterministic artifact |
| `Packages/ReadingData/` | SQLite wrapper, catalog metadata and reader; no journal or sync client yet | `packages/reading-data/` portable contracts; platform stores and server-only `packages/db/` |
| `catalog/scripture/` | 78 registered books, named canons/orders; English verse counts; WEB word counts | Preserve source files, rights evidence, and checksums; do not download or transcribe again |
| `catalog/plans/` | Empty except `.gitkeep` | Remains empty until P8.1; use invented test plans for migration |
| `Server/Sources/DayByWordWeb/` | HTML shell, components, typed strings, settings, routes, CSP and metadata-only logs; catalog checked at startup | `apps/web/` pages/layouts, Route Handlers, API validation, equivalent safeguards |
| `Server/Public/` | CSS, vanilla modules and registered images | Tailwind/global CSS, React client controls, `apps/web/public/`; retain published asset URLs or redirects |
| `apple/App/`, `apple/Shared/` | Today/Plans/Progress placeholders, navigation, component gallery, Settings, localized strings, generated tokens | `apps/mobile/` Expo Router and React Native components; shared tokens/strings |
| `apple/Widgets/Widgets.swift` | Small and rectangular Lock Screen placeholders; no interactive marking | Reproducible Expo widget target/adapter with equivalent placeholder; interactive widget still P8.9 |
| `apple/AppTests/`, `apple/AppUITests/` | Navigation, components, launch and light/dark tours | Port assertions and route matrix; retain a native UI harness where needed |
| `scripts/`, Makefile, `.github/workflows/check.yml` | Swift toolchain/lint/import/color/string checks, Linux container, tours, archive/upload | Node/TypeScript gates and production Compose checks; local Expo builds; manual-dispatch CI stays D31 |

Read these owning files when porting: `docs/scripture.md` (E27–E31),
`docs/catalog-format.md`, `catalog/SOURCES.md`, `docs/editorial.md`,
`docs/design.md`, `docs/product.md`, `docs/urls.md`, and
`docs/release.md`. `docs/engine.md` does not exist yet: writing it is P5.1.
`deploy/` does not exist; `make deploy` currently exits with "not built yet".

## Target layout and dependency boundaries

Use one npm workspace and a committed lockfile; no second web application
from Expo's web export. Pin a supported Node LTS, npm, compatible
Next/React/Tailwind/shadcn versions, Expo SDK and its supported React
Native/React versions, and Postgres image before implementation. Record
the exact compatibility matrix and commands in README at PM.2. Share
TypeScript code rather than assuming both apps require the same React
version. No floating `latest` production images or unpinned build tools.

~~~text
apps/web/                    Next pages, Route Handlers, public assets
apps/mobile/                 Expo Router, app.config.ts, config plugins
packages/reading-engine/     pure TypeScript; no React, Node, DB or native imports
packages/reading-data/       catalog/journal transport types, storage interfaces
packages/catalog-compiler/  Node CLI; validates sources, emits versioned catalog
packages/db/                server-only Drizzle pg schema, client, migrations
packages/design/            generated CSS theme and React Native token values
packages/strings/           typed English strings and interpolation
tests/fixtures/             cross-runtime reference/catalog/parity cases
deploy/compose.yaml         web, postgres, one-shot migration/import services
deploy/Dockerfile           standalone multi-stage image
deploy/caddy/daybyword.com  site snippet to install after host inspection
deploy/                    fresh deploy, check-live, backup, restore scripts
catalog/ design/ docs/      preserved source content and owning documentation
~~~

No database driver, `DATABASE_URL`, auth secret, Node-only compiler module,
or environment reader may enter a client bundle. Test these import
boundaries. Shared packages must resolve under Next's bundler and Expo's
Metro and run under Node, a real browser, and Hermes. A Node-only crypto,
filesystem, date, or SQL API cannot be the shared engine's implementation.

Clients use HTTPS Next.js APIs for catalog delivery and future consented
sync/auth. They never connect to Postgres. To preserve D10/D39 and airplane
mode, local evaluation imports the same engine. This changes E29's
server-only computation detail, not the rule that personal data stays
local at 1.0. A stateless compute endpoint, if needed, uses the same engine
and versioned contracts, keeps nothing, and logs no request body. Do not
create one just to upload data that can be evaluated locally.

## Porting contracts and data

1. **Capture parity before deletion.** Extract input/expected-output
   fixtures from the existing Swift tests, including invalid input and
   compiler diagnostics. Compare semantic outputs, not SQLite file bytes.
   Run the legacy implementation while producing the oracle fixtures; do
   not have the new implementation generate its own expected answers.
   Save the baseline commit and fixture format. Keep fixtures free of Bible
   text and real reader records.
2. **References and counts.** Preserve USFM ids, book naming conventions,
   all registered canons/orders, non-1 chapter/verse starts, exact errors
   for invalid references, canonical serialization, one-chapter display,
   and repeat/omission calculations. Pin 1,189 chapters / 31,102 verses
   for the 66 books, and 754,449 WEB words. Preserve E31's doxology mapping
   and footnote-only verses, and workload rounding/rates (238/183 wpm).
3. **Compiler.** Keep the front-matter/TSV source grammar, stable ids,
   source registry statuses and review levels. Invalid input must leave
   the last complete artifact intact. Release builds exclude sub-reviewed
   plans and reject uncleared sources exactly as today. Test both modes,
   empty catalog, invalid claims, and deterministic ordering/checksum.
4. **Catalog artifact.** Replace runtime `Catalog.sqlite` with a versioned,
   deterministic JSON artifact carrying plans, assignments, computed
   facts, scripture registries/counts, build mode, and content digest.
   Include the numeric word data needed for offline workload computation.
   Version the artifact separately from SQL migrations. Specify canonical
   UTF-8 serialization and checksum inputs; compare schema-3 normalized
   content against the new artifact and document any new hash domain.
   Mobile bundles the release artifact; browsers cache approved active
   plan versions. Never bundle development-only content in production.
5. **Postgres.** Define Drizzle tables for catalog builds (format version,
   digest, build mode), immutable plan versions (composite id/version),
   assignments (plan id/version/assignment id, unique position), facts,
   and scripture resources. Carry schema-3 `catalog_meta`, `plans`,
   `assignments`, `plan_facts`, and `scripture` semantics across; do not
   copy SQLite STRICT/PRAGMA syntax to PostgreSQL. Import only validated
   release artifacts transactionally, with idempotence by digest and no
   overwriting published versions. Use a restricted runtime role and a
   separate migration/import credential. No reader tables at 1.0.
6. **Migrations.** Commit Drizzle TypeScript schema, generated SQL and
   metadata. Use generate/review/migrate, never schema push in production.
   Run migrations/import once under the deploy lock before starting a
   candidate, not from each web process. Prove empty-DB installation,
   repeat execution, failure rollback and last-release compatibility.
   The migration runner and SQL files must be in a runnable image target;
   Next standalone output alone need not contain CLI tooling.
7. **Local records.** Journal/enrollment schemas and their UUIDv7 fold are
   P5.1/P5.4, still open. Establish versioned storage interfaces now;
   implement them there once, with local SQLite/IndexedDB adapters in
   P8.10/P8.11. Never substitute a server database for the offline journal.
   A future export/import preserves ids, plan versions and civil dates.
   DB migrations, catalog versions and journal/export versions are distinct.
8. **Existing installs.** Keep `com.daybyword.app`, widget suffix,
   `group.com.daybyword.app`, `daybyword://` and existing App Store record.
   Inspect a real legacy app container before declaring there is no reader
   data. The source currently persists `appearance` and `referenceSize` in
   UserDefaults and `navigation` in SceneStorage; web modules persist
   display settings. Migrate durable preferences in place with a small
   native bridge where necessary; navigation can fall back safely.
   Catalog files are rebuildable, not personal records. If unexpected
   journal data exists, preserve it and add a tested importer before
   replacing or removing anything. An uninstall/reinstall is not a
   migration test.

## Web and mobile parity

Recreate every route in `docs/urls.md`, the component gallery in development
only, title/headings, active navigation, Settings persistence, reference
copying, unknown-route behavior, and `/up`. Keep existing samples marked
as samples. Do not display generated catalog test fixtures as real plans.
Port `Localizable.xcstrings` and `Strings.swift` into typed shared strings;
retain native extension localization resources if the extension needs them.

Generate Tailwind/shadcn semantic variables and React Native tokens from
`design/tokens.json`. Port the color/contrast checks before replacing the
Swift generator. shadcn is web UI; do not try to render its DOM components
inside Expo. Use React Native controls with the same tokens, voice,
accessible labels, large text, and layout behavior.

Next's hydration scripts require a production CSP designed for Next.
Use per-request nonces and dynamic HTML rendering where required; verify
normal navigation, streaming, errors and offline fallback under the built
standalone server. Do not cache nonce-bearing HTML as a public static
page. Audit shadcn primitives that emit inline style attributes; choose or
adapt components to keep the production no-unsafe policy. Do not silently
add `unsafe-inline` or `unsafe-eval` to ship. A localhost-only development
policy may permit the tooling's documented requirements. Retain same-origin
assets, no remote fonts/scripts/images, no telemetry in Next or Expo
tooling, and metadata-only application/proxy logs. Private API responses
are `no-store` and excluded from shared/Cloudflare/Next caches.

Use local Expo development builds, not Expo Go as a release-parity test.
Prove that the chosen SDK can build the existing placeholder widget and
that the future P8.8/P8.9/P12.4 design has a working extension boundary:
interactive marking while the app is terminated, App Group persistence,
local notifications/actions, and App Intents cannot be assumed from a
JavaScript screen. Prefer supported Expo modules; keep small native
Swift/WidgetKit/Intents adapters and config plugins when needed.
They may render a prepared snapshot or append an intent command, but must
never contain a second scheduling/progress engine. Specify how a command
gets a stable id, is folded once by TypeScript, and refreshes the widget;
do not claim an immediate updated result until tested. If the chosen
extension runtime can host the same TypeScript engine, test it there.
Do not remove a 1.0 widget or action requirement just because Expo Go
cannot run it. Feasibility belongs to PM.6; reader features stay P8/P12.

Preserve automatic/light/dark themes, iPad widths/navigation, AX5 text,
VoiceOver reading order, Reduce Motion, reference spoken labels and
no-permission-until-requested behavior. Export/print/notification/link
adapters remain platform code around the shared rules. No EAS account,
hosted build service or hosted OTA service is required; local Xcode signing
and App Store Connect remain the delivery path.

## Acceptance and removal

Keep the old implementation working until its replacement passes the
corresponding fixtures and surface checks. During PM.2 introduce explicit
legacy/new checks; `make check` must cover every retained active target,
and no failing gate may be hidden by a stub. At PM.11 the sole default gate
uses the new stack. No production request or mobile core path can depend
on a Swift server, Swift Package Manager, XcodeGen or SQLite server catalog.
Native adapters and their Apple build toolchain are the limited exception.

The new `make check` covers frozen installs, formatting/lint/type checks,
import boundaries, token/contrast and string checks, shared-engine cases,
compiler integrity in both modes, real PostgreSQL migration/import tests,
Route Handler tests, and mobile unit tests. `make check-full` adds a
production standalone Compose boot, browser journeys/light/dark and phone
widths, Expo simulator tour/light/dark/large text/offline, native extension
smoke tests where present, and Linux Node/compiler/Postgres tests.
Use maintained test tools appropriate to these runtimes, pin and record
them in E32's follow-up entry; port the existing assertions before
retiring the Swift WebDriver runner and XCUITest targets. Keep manual CI.

Rehearse nightly `pg_dump` backup, encrypted off-server copy and restore to
an isolated database before the first deploy, even with only catalog data.
Restore verification includes roles/grants recreated from protected setup,
catalog digest, migrations and readiness, not only a successful SQL import.
See `docs/deploy.md` for paths, ports and cutover constraints.

PM.11 removes obsolete app/server/packages/scripts and generated assets
only after parity is proved, replaces the Make targets/workflow/release
commands, and searches all active docs for old-stack instructions.
Do not edit BUILD-HISTORY.md or old engineering decisions into a fictional
new-stack history. Keep source-data provenance; replace script paths only
after the new commands exist. Record actual verification and remaining
limits; then resume P5.1. Production provisioning/deploy stays Phase 7,
and the next usable TestFlight milestone stays P8.14.

## Documentation checked for the plan

Checked 2026-11-02. Resolve current docs again when pinning implementations;
these links explain constraints, not a claim that future commands exist.

- [Next standalone output](https://nextjs.org/docs/app/api-reference/config/next-config-js/output):
  copy public/static assets and include workspace packages/data in tracing.
- [Next self-hosting](https://nextjs.org/docs/app/guides/self-hosting) and
  [CSP](https://nextjs.org/docs/app/guides/content-security-policy):
  reverse proxy and nonce-aware rendering.
- [Drizzle migrations](https://orm.drizzle.team/docs/migrations):
  generated, reviewed and applied SQL.
- [Expo SQLite](https://docs.expo.dev/versions/latest/sdk/sqlite/),
  [local app builds](https://docs.expo.dev/guides/local-app-development/),
  [widgets](https://docs.expo.dev/versions/latest/sdk/widgets/), and
  [notifications](https://docs.expo.dev/versions/latest/sdk/notifications/):
  SDK-specific support and native runtime constraints need verification.
- [Tailwind theme variables](https://tailwindcss.com/docs/theme) and
  [shadcn theming](https://ui.shadcn.com/docs/theming): map existing tokens.
- [Better Auth Drizzle adapter](https://better-auth.com/docs/adapters/drizzle):
  intended Phase 14 integration; validate passkey-only/recovery and mobile
  requirements then, rather than enabling email/password defaults now.
- [Compose readiness](https://docs.docker.com/compose/how-tos/startup-order/),
  [Postgres pg_dump](https://www.postgresql.org/docs/current/app-pgdump.html),
  [Caddy Cloudflare module](https://caddyserver.com/docs/modules/dns.providers.cloudflare),
  and [Cloudflare Full (strict)](https://developers.cloudflare.com/ssl/origin-configuration/ssl-modes/full-strict/).
