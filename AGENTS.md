# Working on Day by Word

Day by Word is a Bible reading companion. It helps Christians choose a
reading plan, know what to read today, and keep a trustworthy record of
their reading, while they read in their own Bible: paper, app, or audio. Its
line is *Find your plan. Read your Bible. Keep your place.*

It is a native iPhone and iPad app in SwiftUI and a SvelteKit web version
at daybyword.com, backed by PostgreSQL 18 and Drizzle on the owner's own
machine behind Caddy (stack decision D42). SvelteKit in `web/` serves every
page and is the only server. Swift stays because the native app is Swift;
Python is optional tooling, never a required language or a rewrite.

Every AI agent session follows this file. [BUILD.md](BUILD.md) says *what*
to build and where work stands; this file says *how* to work. When they
disagree about what to build, BUILD.md wins; about how to work, this file
wins.

**No denominational affiliation.** Day by Word is an independent Christian
project and serves readers of every tradition. This repository has no
SOUL.md, statement of faith, or denominational framework, and must not gain
one. Do not read, copy, or adapt the SOUL.md files or faith statements of
the owner's other projects (Grace & Footnotes, Prayerbook Atlas, Beautiful
Corner) for this work. §3 is the whole of this project's voice and conduct.

Contents: [Git rules](#git-rules-owners-standing-instructions) ·
[1. Before you touch anything](#1-before-you-touch-anything) ·
[2. The session loop](#2-the-session-loop) ·
[3. Voice, fairness, and the reader](#3-voice-fairness-and-the-reader) ·
[4. Markers, gates, and who decides](#4-markers-gates-and-who-decides) ·
[5. Stack and engineering rules](#5-stack-and-engineering-rules) ·
[6. Plans, references, and rights](#6-plans-references-and-rights) ·
[7. Definition of done](#7-definition-of-done-for-a-checkbox) ·
[8. Commits](#8-commits) ·
[9. Beyond the repository](#9-beyond-the-repository) ·
[10. Commands](#10-commands) ·
[11. Known pitfalls](#11-known-pitfalls) ·
[12. Keeping this file useful](#12-keeping-this-file-useful)

## Git rules (owner's standing instructions)

These override any other workflow described in this repository or by your
tools.

- Work on `main` only. Never create branches, worktrees, or pull requests.
  Commit directly to `main` and push with `git push origin main`. `origin`
  has two push URLs, GitHub and Codeberg (BUILD.md P0.5), so one push
  updates both.
- No AI attribution anywhere: no `Co-Authored-By` trailers, no "Generated
  with ..." lines, and no crediting Claude, Anthropic, ChatGPT, OpenAI, or
  any AI tool in commit messages, tags, release notes, code, comments, docs,
  or file headers. Use the owner's configured git identity and never change
  git config. Content the project deliberately publishes about AI, such as a
  reader-facing disclosure or the README's "How it is built", is not
  attribution.
- After committing, push `main` right away, and at the latest before the
  session ends. Before committing, run the project's checks, review
  `git status` for stray files, and never commit what `.gitignore` excludes.

## 1. Before you touch anything

1. Run `git pull --ff-only`, `git status`, and `git log --oneline -20`.
   Preserve any work in the tree that is not yours (§8).
2. Read BUILD.md's **Now** table, then the whole of [BUILD.md](BUILD.md)
   once per session: "How agents use this file", the finished-product
   definition, the product principles, the Owner decisions table (D1–D42),
   the Engineering foundations, the phases to version 1.0, and the Handoff
   notes at the bottom. Do not read `BUILD-HISTORY.md`, `docs/roadmap.md`
   (the work after 1.0), or `docs/research/` unless an item or a check
   points there (§8, "Keeping BUILD.md short").
3. Read the entries of `docs/decisions.md` that bear on your item, and any
   document linked from the items you are about to work on:
   `docs/engine.md` for engine work; `docs/catalog-format.md`,
   `docs/editorial.md`, and `catalog/SOURCES.md` for plans;
   `docs/product.md` and `docs/design.md` for anything a reader sees;
   `docs/urls.md` and `docs/web.md` for the web; `docs/deploy.md` before
   touching the server; `docs/release.md` before an archive or TestFlight.
4. Run `make check` (§10), so you know the real state before trusting any
   checkbox. If it fails on a clean tree, fixing it is your first task.

The owner (GitHub `dunamismax`) decides the product. In anything this
project publishes, refer to the owner only as the owner, and never attribute
a church, tradition, or faith story to them.

## 2. The session loop

1. The owner's request in chat comes first. Otherwise take the **first
   unchecked `- [ ]` item in the earliest phase that is not complete**
   (BUILD.md's **Now** names it), skipping items whose gate is
   still closed and [OWNER] steps still waiting on the owner (§4). Phases
   are ordered, and items inside a phase are ordered unless marked
   *(parallel-safe)* or the phase says otherwise. Phase 10 (the launch
   catalog) may run alongside Phases 9–17.
2. Inspect the relevant code before writing any. Checkboxes can drift from
   reality: if an item is already done, verify it and tick it; if a ticked
   item is broken, untick it and say why in the Handoff notes. If the broken
   item was in a phase already moved to `BUILD-HISTORY.md`, leave the history
   as it is and add a new item to the earliest open phase that names it.
3. Implement the item completely and no larger than it needs to be: code,
   tests, docs, and verification. A feature that exists on both the app and
   the web lands on both within the same milestone (D37, D39). If an item
   asks for more than version 1.0 needs, build the 1.0 part and move the
   rest to `docs/roadmap.md`'s Phase 28 with a note.
4. Verify it (§7), and tick the box only when it meets the definition of
   done.
5. Commit (§8), then take the next item. Complete as many items as you can
   in one session, and stop only at the end of your budget. When you meet a
   blocker, clear it or work around it, record why, and keep going.
6. Before ending: make sure `make check` passes (and `make check-full` at a
   milestone, or before a TestFlight build or a deploy), push, update
   BUILD.md's **Now** and Build status tables, and **replace** the Handoff
   notes with the current state (what you finished, what is half-done, what
   is blocked, and anything surprising). Keep them under 25 lines; history
   lives in Git. Then tell the owner in chat what you finished, what comes
   next, and exactly what waits on them.

Never leave `main` broken. If you must stop mid-item, either finish it to a
passing state or revert the partial work, and record it in the Handoff
notes.

If an item is wrong, too large, or out of order, do not silently skip or
delete it. Split it into sub-items (`P5.6a`, `P5.6b`), rewrite it, move the
part 1.0 does not need to the roadmap, or add a dated note under it, and say
what you changed in the Handoff notes.

## 3. Voice, fairness, and the reader

Day by Word serves people who want to read the Bible and find planning and
consistency hard. Every rule here protects that reader.

- **Every tradition on its own terms.** Describe each tradition's plans,
  calendars, and canon as its informed members would recognize them, from
  their own sources, in neutral language. Label precisely: the edition (1662
  is not 1871, 1922, or 1961; the 1979 book is not the 2019 book), the
  tradition, and the calendar rule. Never present one canon, translation,
  tradition, or calendar as the norm against the others, never disparage
  any church, and never take a side on a question Christians dispute.
- **The plan, not a sermon.** Plan descriptions say what a plan is, whom it
  suits, its workload, what it covers, and its limitations. Day by Word does
  not interpret Scripture, preach, or give spiritual direction.
  Recommendations are practical (time, goals, reading days) and never claim
  divine authority: never "God wants you to read this."
- **The reader's own Bible.** Day by Word never shows Bible text (D13).
  Reader-facing text cites references and never quotes passages.
- **Records describe activity.** Reading records cannot measure
  faithfulness, spiritual maturity, or understanding, and nothing in the
  product may suggest that they do. A completed plan is not proof of
  devotion, and a missed day is not a failure.
- **No guilt mechanics.** No shaming, countdowns, badges, points, levels,
  leaderboards, loss-framed streaks, or "you're falling behind" pushes. A
  missed day is simply a day, and returning is welcomed. Celebrate quietly:
  returning after a gap, finishing a book, keeping a rhythm the reader
  chose. Streaks follow BUILD.md D17.
- **Quiet and readable.** No social feed, rankings, pop-ups, rating prompts
  on Today, or promotions. Never optimize for minutes spent in Day by Word:
  success can be ten seconds in the app and twenty minutes in the Bible.
  Ask for notification permission only when the reader chooses a reminder.
- **Honesty in the interface.** Opening a link is not reading, and a skip is
  not reading; the reader confirms what they read. Time estimates are
  approximate, and the app says so. Backup and offline status are always
  truthful. Never promise an integration (for example syncing with another
  Bible app) that has not been verified.
- **Privacy is care.** Reading history and tradition preferences are
  sensitive, and in some laws they are special-category data (Research
  finding 11, in `docs/research/findings.md`). They are private by default,
  kept on the device unless the reader consents to more (D10), exportable,
  and deletable. No analytics, ever (D12).
- **No AI in the product** (D23). There are no generative models, chat, or
  AI recommendations anywhere. The single exception is Apple's on-device
  text recognition for private photo import, with every reference confirmed
  by the reader.
- **Not a church, not a publisher.** Day by Word speaks for no church,
  denomination, ministry, or publisher. Never use a church's or ministry's
  seal, logo, or wording that implies endorsement. A link is a destination,
  not an endorsement. Partnership candidates are never called partners until
  an agreement exists.
- **Honesty about agents' own work.** Never claim personal faith, prayer, or
  a reading life. Never impersonate God, Christ, any biblical figure, a
  pastor, or a church. Generated text is never presented as Scripture or as
  a source's own wording. Never claim that a review, permission,
  partnership, endorsement, or test happened unless it did and BUILD.md
  records it.
- **The voice.** Plain, warm, brief, and concrete. Write for a tired reader
  at six in the morning with a paper Bible open: "Welcome back. Here's where
  you left off," never "You missed 5 days!" Use the reader's words (reading,
  plan, today), explain terms such as *lectionary* and *Daily Office* when
  they appear, and avoid insider phrases that belong to one tradition. No
  flattery, exclamation-mark enthusiasm, or manipulative urgency.

## 4. Markers, gates, and who decides

**Agents build Day by Word autonomously** (owner decision D3, 2026-10-30).
They make every implementation decision, settle new open questions, do
every item, provision and deploy the server (D34), and use the owner's
Apple Developer account through Xcode and App Store Connect (D33). Decide
on the evidence, and write the reasoning down where the next agent will find
it: a new decision goes in BUILD.md's Owner decisions table as
`(agent, date)` with its reasons, or in `docs/decisions.md` for
engineering. The owner's answers in D1–D42 are the product's direction. An
agent may refine how one is carried out, but never reverses one without
asking the owner.

The only limits are honesty and the host's own safety rules. Where those
rules stop an agent from a step (entering the owner's passwords or keys,
making a payment, accepting terms, sending a message in the owner's name,
or publishing where the host requires a confirmation), do everything else,
ask the owner in chat for exactly that step, list it under "Waiting on the
owner" in BUILD.md's **Now**, and continue with other work meanwhile.

- `- [ ]` open, `- [x]` done and verified.
- **[OWNER]**: a step only the owner can take: signing in to the owner's
  accounts (Cloudflare, Codeberg, payment services), the owner's own review
  or choice (the expert review of D15, the design choice of D18), supplying
  images (D19), or confirming a letter (D38). Agents prepare everything
  around it and tick it once it is verifiably done.
- **[GATE Dn]**: depends on a decision that opens later (D6 for Android
  after 1.0, D11 for paid extras after launch). When it opens, record the
  decision and its reasons.
- **[GATE DEMO]**: begins once the first usable build is on TestFlight and
  at daybyword.com (BUILD.md P8.14).
- **[RIGHTS]**: the item uses a third-party plan, schedule, table, dataset,
  font, or image. Agents research and decide (D21): identify editions and
  printings, read title and copyright pages, check digital editions' terms,
  and mark the source `cleared` or `rejected` in `catalog/SOURCES.md` with
  the evidence. A public-domain source may be cleared on documentary
  evidence (publication date, a published release, a stated licence),
  recorded per territory. A permission-based source is cleared only when the
  written permission is recorded.
- **[REVIEW]**: editorial review of plan content or of anything describing
  a tradition, under `docs/editorial.md`. Agents bring an item to
  `reviewed` (checked against its source, two passes for transcriptions,
  wording checked against §3) and may approve original plans at that level.
  The `expert` level, which prayer-book plans need, is the owner's own
  review (D15). Agents prepare the review packet and record the review once
  it happens, and never claim it before then.

If an item cannot be finished yet because something it needs does not
exist, build what it needs first or move to the next item, and say so in the
Handoff notes.

## 5. Stack and engineering rules

**The stack (D42, E36): SvelteKit 3 · Svelte 5 · TypeScript · Tailwind CSS 4
· PostgreSQL 18 + Drizzle ORM · Node (adapter-node) · Caddy**, with the
existing SwiftUI app. It replaced D41/E33's Astro plan, which replaced
D40/E32's Next/Expo plan; E33's engine and data boundaries still hold. No
Next.js, Astro, React, Expo, or Tauri migration. SvelteKit 3, Svelte 5,
Tailwind 4, and Drizzle differ a lot from older tutorials: look up their
current documentation (Context7 or the official docs) before writing
framework code, rather than relying on memory.

**Web** (`web/`)
- SvelteKit 3 with Svelte 5 runes and TypeScript, built by
  `@sveltejs/adapter-node` into a standalone Node server that
  `web/server.ts` wraps for headers, cache policy, and logs. Configuration
  lives in the `sveltekit()` plugin in `web/vite.config.ts`; SvelteKit 3
  reads no `svelte.config.js`.
- Pages are `src/routes/**/+page.svelte` with `+page.server.ts` loads;
  forms use form actions with progressive enhancement; app and client APIs
  are `src/routes/api/v1/**/+server.ts`. Prerender public content where
  useful and set `csr = false` on pages that need no interaction (today,
  every page: E38). The app APIs need a Node runtime, so the site is never a
  static-only deployment.
- Styling: Tailwind CSS 4 through `@tailwindcss/vite`, one entry at
  `web/src/app.css`, with Morning's theme variables generated from
  `design/tokens.json` into `web/src/tokens.css`. No component kit; Svelte
  components are written here and preserve Morning rather than impose a
  new UI.

**Server data**
- PostgreSQL 18 through a server-only Drizzle schema in
  `web/src/lib/server/`, imported as `#lib/server/…` (SvelteKit 3 refuses
  to bundle any `server` directory into the browser), with reviewed
  generated SQL migrations in `web/drizzle/`.
- No server SQLite, better-sqlite3, libSQL, Litestream, or SQLite-file
  access from Python. The project has its own database, roles, private
  network, and persistent volume. No browser or native client ever holds a
  database connection or credentials.
- At 1.0 the server stores public catalog data only; transient compute
  requests never persist personal records.

**Native** (`apple/`)
- Keep the SwiftUI iPhone and iPad app with Observation (`@Observable`),
  WidgetKit, App Intents, and UserNotifications. Swift 6.4.2 in
  `.swift-version`, Swift 6 language mode with complete concurrency
  checking; Xcode 27 and the iOS 27 SDK, iOS and iPadOS 26 minimum (D7).
- Keep XcodeGen's `apple/project.yml` and the `make run`, `test-app`, and
  `archive` commands working. Never hand-edit the generated Xcode project.
  A Mac target uses SwiftUI only when needed; this stack implies no new
  native platform.
- Local data: the existing `ReadingData` SQLite stays for offline reading
  and the bundled catalog. SwiftData or GRDB are for a demonstrated storage
  need, never a mandatory substitution, and never replace or connect to the
  PostgreSQL server. Native network operations call the SvelteKit API over
  HTTPS.

**Reading logic**
- One specification, `docs/engine.md`, with versioned wire contracts and
  shared JSON cases in `tests/fixtures/`. Swift `ReadingEngine` owns the
  native rules; the TypeScript domain module `web/src/lib/domain/` owns the
  web's server and browser rules (E33's explicit two-runtime exception).
- Both runtimes pass identical cases. No rules in Svelte components, form
  actions, routes, SQL, or utility scripts. A new engine rule gets its cases
  and its specification first, then code, then parity in both runtimes.
- Keep the needed Swift packages and the catalog compiler with their macOS
  and Linux tests. The compiler's rights, coverage, and source checks are
  the release gate. Its deterministic export is the only way catalog data
  reaches PostgreSQL (PM.14); bundled, read-only native catalog artifacts
  stay apart from mutable server data. Calendar rules stay compiler-only,
  never rebuilt in app views or routes.

**Python, only when needed.** Use uv for environments, dependencies, and
runs, and ruff, if a utility justifies Python. Typer, httpx, and Pydantic
are optional per task; no mandatory bundle or mass port of scripts.
Reports and maintenance query PostgreSQL with a least-privilege
connection. Recurring jobs are systemd timers. No standalone Python
backend.

**Scope.** Keep D39's offline, no-account core: local native records and
the browser's IndexedDB. Better Auth inside SvelteKit with Drizzle waits
for Phase 14 and keeps the optional passkey and recovery-code design (D8).
Billing stays gated (D11). D23 excludes every AI feature and model SDK.

**Versions and dependencies.** Pin Node, pnpm, SvelteKit, Svelte, Vite,
Tailwind, Drizzle, pg, and PostgreSQL 18, with an exact lockfile, and keep
Swift pinned. Record any real new package in `docs/decisions.md` before
adding it. No analytics, tracking, advertising, session replay, remote
fonts or CDNs, or phone-home services; disable build and framework
telemetry. Never copy code from the owner's other projects (D22).

**Dates and the journal.** Civil dates, resolved once at the device edge;
never a `Date` instant as a reading day. Reminders use wall-clock time in
IANA time zones. Events use UUIDv7 ids, append-only deterministic folds,
idempotent retries, and undo events; deletion only at the reader's request.

**Tests and gates.** `make check` covers the active Swift targets and the
SvelteKit lint, svelte-check, unit tests, production build, real
PostgreSQL 18 migrations and import, and the engine cases. `make
check-full` adds the browser engine run, both tours, and Linux. CI is
manual dispatch only (D31). Port existing assertions before retiring a
tool.

**Design and accessibility.** `design/tokens.json` and `docs/design.md` are
authoritative. Generate Apple assets and web theme variables from them
(`make tokens`); no raw colors and no new art. AX5 Dynamic Type,
VoiceOver, Reduce Motion, and WCAG 2.2 AA, with light, dark, zoom, and
keyboard checks. State always has words or symbols, never color alone.
Interface strings stay localizable.

**Security.** Same-origin assets only, and a strict production CSP with no
`unsafe-inline` or `unsafe-eval`, through SvelteKit's `csp` option (hashes
for prerendered pages, nonces for rendered ones); test hydration and
Tailwind output under it in the production build. Logs carry method, route
pattern, status, and duration only, never request bodies, concrete plan
paths, tokens, or personal data. Private API responses are `no-store` and
kept out of shared caches. No personal data in URLs, except the future
protected, revocable calendar-feed credential.

**The live host** (docs/deploy.md; inspect before changing anything; the
host's web platform contract, `ubuntu-vm-backup/docs/web-platform.md`,
governs and wins where this file differs)
- `ubuntu-vm`. `daybyword-web.service` runs `/opt/node-26/bin/node
  server.ts` from `/srv/www/daybyword.com/current` (an absolute symlink to
  `releases/<commit>`) as `daybyword-web` on 127.0.0.1:4318, with the
  contract's sandbox. No production container (E46).
- The database is `daybyword` on the host's PostgreSQL 18 cluster
  (127.0.0.1:5432), every table in schema `app`: `daybyword_owner` (no
  login), `daybyword_migration` (deploy only, `SET ROLE`), `daybyword_web`
  (read-only). Credentials are `/etc/web-apps/daybyword/web.env` and
  `migration.env`, root-only; the code reads `DATABASE_URL`.
- Deploys (`make deploy`) build on the host as the checkout owner, then run
  `deploy/bin/activate.sh` inside the shared lock (`with-deploy-lock`):
  backup, migrate and import, a candidate on a 44xx port, switch, verify.
  Fix-forward only: no rollback scripts, pointers or old releases kept to
  go back to. Caddy's site file is `/etc/caddy/sites/daybyword.com.caddy`,
  from `deploy/caddy/daybyword.com.caddy`, changed only with `caddy-apply`.
  Only `origin/main` releases are served.
- DNS is owner-managed, DNS-only (not proxied) Cloudflare records pointing
  at the host; the host's Caddy obtains its own Let's Encrypt certificates.
  No Cloudflare DNS challenge, Caddy DNS plugin, token, or proxy or SSL-mode
  work; never change Cloudflare settings. Coordinate changes to shared
  binaries, and never edit another site.
- Backups: nightly `pg_dump` and a monthly isolated restore check (systemd
  timers, `deploy/bin/backup.sh` and `restore-check.sh`), and
  ubuntu-vm-backup's daily encrypted dump of the cluster off the server.

**Secrets.** Never commit `.env` files, signing keys, certificates,
profiles, `Secrets.xcconfig`, database credentials, or DNS tokens. No
secrets in public variables, bundles, images, or logs. Read
`docs/deploy.md` before any host work.

## 6. Plans, references, and rights

- **Plans are received, not reconstructed.** Transcribe a historic plan from
  an identified printing and proofread it twice against the page images
  (`docs/editorial.md`). Never type a schedule from memory, never copy one
  from another app, website, or modern reprint, and never "correct" a source
  toward a more familiar form. Record a source's own errors as errata and
  keep the original visible.
- **Original plans are Day by Word's own.** They are built from verse data
  and documented rules (for example, balanced by reading time), labeled as
  original, and reviewed. Never derive one from a contemporary publisher's
  version of a familiar plan simply because its underlying idea is old.
- **References are verified, and claims are computed.** The compiler checks
  every reference against its versification and computes coverage, repeats,
  and omissions. Never assert a coverage claim by hand. A lectionary never
  inherits a "whole Bible" claim because it lasts a year. Keep the source's
  displayed wording wherever normalizing would lose meaning.
- **Every catalog item has a rights record** in `catalog/SOURCES.md`. Free
  access on a website does not grant permission to republish a schedule in
  an app. References, compiled schedules, devotional prose, Bible
  translations, artwork, and branding are each considered separately. Do
  not assume a source is public domain because it is old or free online.
  Nothing is served unless it is `cleared` for the readers it reaches, and
  licensed items keep every limit of their terms: credit lines,
  territories, offline and export rights, adaptation rights, and any ban on
  AI use.
- **External directory entries** describe a plan and link to its publisher.
  They never suggest that the schedule is available inside Day by Word.
- **Editions and calendars are labeled exactly** (Research finding 7).
  Daily Office readings are never confused with Sunday or Communion
  lectionaries. Chronological plans name their approach and are never
  presented as the one correct order.
- **Calendar and lectionary facts** follow D20: facts only, cited, and
  cross-checked against two independent sources with every difference
  listed. Rules a source does not state are labeled "app convention", with
  the reason.
- **Canon and book names** follow D29. Adaptations (substitutions, omitted
  books) are labeled as adaptations, are offered only where the plan's
  permissions allow them, and never replace the original schedule.
- **No Bible text** (D13). Word counts from a cleared public-domain text are
  stored as numbers for workload estimates; the text itself never ships and
  is never displayed.
- **Images and icons** follow D19. Agents never draw, redraw, or generate
  them; they write prompts in `design/image-prompts.md` for the owner.
- **Permission letters** (D38) are drafted in `docs/owner-drafts/`, kept
  generic while the repository is public (D4), and sent only after the owner
  confirms each one. Correspondence stays off the repository.
- **People's words stay private.** Beta feedback and support mail are
  anonymized before anything enters the repository. Never commit a reader's
  name, contact details, or identifiable story.
- Never invent a plan's source, a reviewer, a permission, a church's
  details, a statistic, or a test result.

## 7. Definition of done for a checkbox

An item is done only when all of these hold:

1. `make check` passes: the toolchain, formatting, imports, design tokens
   and raw colors; the web gate (lint, svelte-check, unit tests, the
   production build booted and checked, the catalog export, schema drift,
   and real PostgreSQL 18 tests); the catalog compile and integrity suite;
   the package tests; the app's unit tests; and the String Catalog. The engine cases pass in both runtimes. The build has zero
   warnings in the touched targets (xcodebuild prints warnings only for
   files it recompiles, so touch the sources or clean before trusting
   that).
2. User-visible work is seen working once, where it runs: Apple work in the
   iOS Simulator (pick the device with `scripts/sim-destination.sh`), with
   VoiceOver labels on new controls; web work in a real browser against
   `make serve-web`, with the console free of errors and CSP violations.
   Widgets, notification actions, and App Intents are exercised where they
   run, not only in unit tests. Do not commit routine screenshots.
3. Engine changes have their cases, written before the code.
4. Plan content meets its review level, its claims are verified by the
   compiler, and its rights entry is `cleared`, or the plan stays out of
   release builds.
5. Server changes that are deployed pass `deploy/bin/check-live.sh`
   (`make deploy` runs it on the candidate, the live port, and
   https://daybyword.com), and the owner's other sites still answer as
   before.
6. The documents the item changes are updated, briefly.
7. The BUILD.md box is ticked in the same commit as the work, with **Now**
   and the Build status table updated.

**At each milestone, and before every TestFlight build or deploy**, run
`make check-full` (`make check`, the engine cases in a browser, the web
tour in light and dark at desktop and narrow widths, the app tour in light
and dark, and the Swift packages on Linux), and check by hand what the
tours cannot: a phone width and 200% text on the web, one large Dynamic
Type size, and dark mode in the new screens. Fix what it finds before
shipping.

Never claim verification you did not perform. If a step could not be run (no
network, a missing tool, no device), say so in the commit body and the
Handoff notes instead of ticking the box.

## 8. Commits

- One commit per completed BUILD.md item, or one for a group of related
  items finished together. Use an imperative subject of 72 characters or
  fewer that starts with the step id, for example
  `P5.5: Keep the next unread reading next at the reader's pace`. The body
  says what changed and why. Work that is no item gets a plain imperative
  subject.
- Pull with `--ff-only` before starting, and never force-push `main`.
- Other sessions may work in this checkout at the same time and leave
  staged or half-finished changes. Commit only your own files (`git commit
  -- <paths>`), and if their edits break the build, verify your change in a
  scratch copy of `main` plus your changes.
- The repository is public (D4), so every push publishes. Never commit
  secrets, correspondence, readers' personal data, or anything a licence
  forbids publishing.
- Keep documentation current, useful, and short: update the owning document
  in place, and keep history in BUILD.md's notes, the decision tables, and
  Git, as BUILD.md's "How agents use this file" describes. Add a decision
  entry only for a real choice between alternatives, not to restate what an
  item already says.

### Keeping BUILD.md short

BUILD.md holds the plan for the work still ahead to version 1.0, so that
every session can read it in full without filling its context with finished
or distant work. Finished phases move to `BUILD-HISTORY.md`, and the work
after 1.0 lives in `docs/roadmap.md` (D39); no session reads either by
default.

- **A phase is finished when every item and sub-item in it is ticked.** A
  phase with any open item, including an [OWNER], [GATE], [RIGHTS], or
  [REVIEW] item, stays in BUILD.md.
- **In the commit that ticks a phase's last item**, move the phase's whole
  section from BUILD.md to the end of `BUILD-HISTORY.md` unchanged: its
  heading, introduction, items, sub-items, and every Note and Result. Add a
  line under the heading saying when it moved. In BUILD.md, leave the phase
  heading with a single line, "Finished; its items and notes are in
  BUILD-HISTORY.md.", and keep the phase's row in the Build status table.
- **Item ids are never reused.** A moved item keeps its id, so references
  such as "P1.12" in code, docs, and commits still resolve.
- **The history is a record.** Never edit a moved entry except to repair a
  broken link. A moved item that later proves broken gets a new item in the
  earliest open phase (§2).
- **Open phases stay lean too.** A Note or Result under an item says in a
  few lines what was done, where it lives, and what was not verified. Longer
  evidence belongs in the commit body, `docs/decisions.md`, the owning
  document, or `catalog/SOURCES.md`. The **Now** table and the Handoff
  notes are replaced each session, never appended to.
- **What stays in BUILD.md while it guides future work:** **Now**, "How
  agents use this file", the finished-product definition, the product
  principles, the Owner decisions table, the Engineering foundations, the
  Build status table, and the Handoff notes. The research findings are in
  `docs/research/findings.md` and keep their numbers.
- **When 1.0 ships**, move the next phases from `docs/roadmap.md` into
  BUILD.md whole, with their ids, as the next work.
- **Read `BUILD-HISTORY.md` only when you need it:** when an open item, a
  document, or a failing check refers to a finished item and you need its
  evidence, and then only that item's entry.

## 9. Beyond the repository

**The server** (D34, standing permission). Agents may SSH as root to
`ubuntu-vm` to provision, deploy, back up, and maintain daybyword.com, on
these conditions:

- Before any server change, record how the owner's other sites answer, and
  check them again afterward.
- Archive `/etc/caddy` before changing anything in it. Add only
  daybyword.com's own site file and never edit another site's file or the
  main Caddyfile's other contents.
- Touch no other site, service, user, or database, and run deploys inside
  the server's shared deploy lock.
- For off-server backups, add only daybyword.com's own entry to
  `ubuntu-vm-backup` (BUILD.md D34's note) and change nothing else there.

**Other services.** Cloudflare DNS and Email Routing, Codeberg, and payment
accounts are the owner's: agents verify what the owner set up (`dig`,
`git remote -v`) but never sign in. The Apple Developer account is the
owner's individual membership (D33): agents use it through Xcode and App
Store Connect where the owner is signed in, within the host's safety rules.
Letters go out only after the owner confirms each one (D38).

**Developer tools** (D3): on the owner's Mac, agents may install the
developer tools the work needs without asking: Homebrew formulae and casks,
needed Node/pnpm and Swift tools, uv/ruff only for justified Python work,
and user-local tools. Prefer well-known, maintained tools from their
official sources, and record in README.md's prerequisites table any tool a
script or `make check` depends on. This does not cover `sudo`, macOS
system or security settings, paid software, or adding a package dependency
(§5 and `docs/decisions.md` govern that).

Agents never:

- change this repository's visibility, or fork or mirror it beyond the
  Codeberg mirror the owner sets up (D4, D32);
- change or copy from the owner's other repositories (`prayerbook-atlas`,
  `beautiful-corner`, the Grace & Footnotes site), apart from daybyword.com's
  own entry in `ubuntu-vm-backup` (D22, D34);
- contact the operators of daybyword.org, or publishers, ministries,
  churches, or beta readers, except through letters and invitations the
  owner has confirmed;
- add a SOUL.md, a statement of faith, or a denominational position;
- add Bible text (D13) or any AI feature (D23) to the product;
- serve anything on the owner's server but what this repository defines;
- claim a review, permission, partnership, endorsement, or result that did
  not happen.

## 10. Commands

`make help` lists every target. The ones a session uses most:

| Command | What it does | When |
|---|---|---|
| `make check` | Lint, the web gate, the catalog in both modes, package and app tests, and the String Catalog | Before every commit |
| `make check-full` | `check`, the engine cases in headless Firefox, both tours in light and dark, and Linux | At milestones, before TestFlight or a deploy |
| `make check-web` | The web part of `check` alone: lint, svelte-check, unit tests, production build booted, export check, schema drift, `test-db` | While working on `web/` |
| `make test-db` | Migrations, the catalog import, and the roles on a throwaway PostgreSQL 18 cluster | After schema or import changes |
| `make serve-web` | The SvelteKit production build on http://localhost:8080 (`PORT=…`), with the release catalog in a throwaway PostgreSQL (`scripts/with-catalog.sh`) and the component gallery | Seeing web work in a browser |
| `make run` | Build, boot a simulator, install, and launch the app (`SIM_DEVICE=…`) | Seeing app work |
| `make test-domain-browser` | The shared engine cases in a real browser | After engine changes |
| `make tour-web`, `make tour-app` | Every section in light and dark, with semantic checks and screenshots | UI changes; part of `check-full` |
| `make test-linux` | The Swift packages on Linux in a container | Part of `check-full` |
| `make tokens` | Regenerate color assets, `DesignTokens.swift`, and `tokens.css` from `design/tokens.json` | After a token change |
| `make db-generate NAME=…` | Generate a SQL migration from the Drizzle schema; review it before committing | Schema changes |
| `make deploy` | Deploy `origin/main` to daybyword.com: build and check on the host, a candidate first, then live | Shipping; run `make check-full` first |
| `make archive`, `make testflight` | A signed Release archive and its upload (docs/release.md) | TestFlight builds |
| `make format` | Format the Swift and web sources in place | Before committing |

## 11. Known pitfalls

Durable lessons from earlier sessions. Add to this list when you find one;
remove an entry once it no longer applies.

- **Never name a source folder `build`.** `.gitignore` and
  `web/.prettierignore` skip every `build/` folder, so its files would
  silently go uncommitted and unformatted (the production tests live in
  `web/test/production/` for this reason).
- **No SvelteKit client runtime yet (E38).** SvelteKit 3.4's route
  announcer writes an inline `style` that the strict CSP refuses, so every
  page sets `csr = false` and Settings and Copy use small same-origin
  modules in `web/static/assets/`. When a page needs real interaction
  (P8.10), choose among E38's options; never weaken the policy.
- **SvelteKit 3 differs from SvelteKit 2.** Private environment variables
  come from `$app/env/private` through `src/env.ts`; route parameter
  matchers are `src/params.ts` (`defineParams`); there is no `ORIGIN`
  variable (use `paths.origin` or Caddy's Host header).
- **A form posts only with the page's origin.** SvelteKit refuses a form
  POST whose `Origin` is not the site's ("Cross-site POST form submissions
  are forbidden"). Keep `Referrer-Policy: same-origin` (under
  `no-referrer` browsers send `Origin: null`) and `server.ts`'s
  `X-Forwarded-Proto` default for direct HTTP requests (E54).
- **Page text is checked against the string table and the catalog.** The
  production tests refuse a page that shows words from anywhere else, so
  a new interface word is a `strings.ts` key, and table text and catalog
  text go in separate elements. The table's voice test refuses "missed",
  "behind", "streak", "failed" and "faithful" in any string.
- **Our own plans' schedules are computed** (`scripts/plans.swift`,
  docs/plans.md). Never edit a schedule by hand: `make check` compares
  each with what its rule gives.
- **PostgreSQL 17 comes first on the owner's PATH.** `scripts/with-postgres.sh`
  finds Homebrew's postgresql@18 itself; do not "fix" the PATH.
- **xcodebuild hides warnings** in files it does not recompile, so a clean
  build log is not proof of zero warnings (§7).
- **Pinned versions are enforced.** `make check` refuses any Swift, Node,
  or pnpm version other than the pinned one; install the pinned version
  rather than loosening the check.

## 12. Keeping this file useful

Edit this file when you find a durable convention, a verified command, or a
recurring pitfall that will help the next session, and keep it current when
the stack or the host changes. Session results, temporary workarounds, and
plan changes go in BUILD.md (its **Now**, notes, and Handoff notes), not
here.
