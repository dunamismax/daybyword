# Working on Day by Word

Day by Word is a Bible reading companion: an iPhone and iPad app and a web
version at daybyword.com, self-hosted by the owner. D40 (2026-11-02) directs
the rewrite to Next.js/React/Tailwind/shadcn, PostgreSQL/Drizzle, Docker
Compose and Expo. The checked-in implementation is still SwiftUI and
Hummingbird; BUILD.md Phase M must replace it before feature work resumes.
Read [docs/stack-migration.md](docs/stack-migration.md) for the inventory,
target layout and parity requirements. It helps Christians choose a
reading plan, know what to read today, and keep a trustworthy record of
their reading, while they read in their own Bible: paper, app, or audio. Its
line is *Find your plan. Read your Bible. Keep your place.* Every AI agent
session follows this file.

**No denominational affiliation.** Day by Word is an independent Christian
project and serves readers of every tradition. This repository has no
SOUL.md, statement of faith, or denominational framework, and must not gain
one. Do not read, copy, or adapt the SOUL.md files or faith statements of
the owner's other projects (Grace & Footnotes, Prayerbook Atlas, Beautiful
Corner) for this work. §3 is the whole of this project's voice and conduct.

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
  reader-facing disclosure, is not attribution.
- After committing, push `main` right away, and at the latest before the
  session ends. Before committing, run the project's checks, review
  `git status` for stray files, and never commit what `.gitignore` excludes.

## 1. Before you touch anything

1. Read [BUILD.md](BUILD.md) in full once per session: "How agents use this
   file", the finished-product definition, the product principles, the
   Owner decisions table (D1–D40), the Engineering foundations, the phases
   to version 1.0, and the Handoff notes at the bottom. Do not read
   `BUILD-HISTORY.md`, `docs/roadmap.md` (the work after 1.0), or
   `docs/research/` unless an item or a check points there (§8, "Keeping
   BUILD.md short").
2. Read the entries of `docs/decisions.md` that bear on your item, and any
   document linked from the items you are about to work on: `docs/engine.md` for engine work;
   `docs/catalog-format.md`, `docs/editorial.md`, and `catalog/SOURCES.md`
   for plans; `docs/product.md` and `docs/design.md` for anything a reader
   sees; `docs/deploy.md` before touching the server.
3. Run `git status`, `git log --oneline -20`, and `make check`, so you know
   the real state before trusting any checkbox.

The owner (GitHub `dunamismax`) decides the product. In anything this
project publishes, refer to the owner only as the owner, and never attribute
a church, tradition, or faith story to them.

## 2. The session loop

1. **Phase M is first, before Phases 0–18.** Do not start P5 or later work
   until the rewrite's exit checks pass. Historical completed phases stay
   historical; their new-stack parity is verified in Phase M.
   Find the **first unchecked `- [ ]` item in the earliest phase that is not
   complete**, skipping items whose gate is still closed and [OWNER] steps
   still waiting on the owner (§4). The design session (P2.3) was a hard
   stop until the owner chose the design; it finished on 2026-11-01 (D18).
   Phases are ordered, and items inside a
   phase are ordered unless marked *(parallel-safe)* or the phase says
   otherwise. Phase 10 (the launch catalog) may run alongside Phases 9–17.
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
   milestone, or before a TestFlight build or a deploy), push, update the Build
   status table in BUILD.md, and **replace** the Handoff notes with the
   current state (what you finished, what is half-done, what is blocked, and
   anything surprising). Keep them under 25 lines; history lives in Git.

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
  finding 11, in `docs/research/findings.md`). They are private by default, kept on the device
  unless the reader consents to more (D10), exportable, and deletable. No
  analytics, ever (D12).
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
engineering. The owner's answers in D1–D40 are the product's direction. An
agent may refine how one is carried out, but never reverses one without
asking the owner.

The only limits are honesty and the host's own safety rules. Where those
rules stop an agent from a step (entering the owner's passwords or keys,
making a payment, accepting terms, sending a message in the owner's name,
or publishing where the host requires a confirmation), do everything else,
ask the owner in chat for exactly that step, and continue with other work
meanwhile.

- `- [ ]` open, `- [x]` done and verified.
- **[OWNER]**: a step only the owner can take: signing in to the owner's
  accounts (Cloudflare, Codeberg, payment services), the owner's own review
  or choice (the expert review of D15, the design choice of D18, which is a
  hard stop under §2), supplying
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

D40 is the current stack decision. The Swift implementation remains only
until Phase M proves its replacement. Historical engineering entries remain
in docs/decisions.md, superseded by E32 where they name the old stack.
[docs/stack-migration.md](docs/stack-migration.md) defines the porting
contracts; [docs/deploy.md](docs/deploy.md) defines the planned host layout.

- **One engine, everywhere.** `packages/reading-engine` is pure TypeScript
  for references, schedules, progress and reminder rules. Next.js, Expo,
  the compiler and browser offline code import that same implementation.
  No view, Route Handler, SQL query or native extension reimplements it.
  For new engine work write docs/engine.md and cases before code.
- **Web/API** (`apps/web`): Next.js App Router, React, TypeScript,
  Tailwind CSS and locally owned shadcn/ui components. Build
  `output: 'standalone'` for a plain Node server, no Vercel services or
  hosting-specific dependencies. Semantic server-rendered public pages,
  same-origin assets and a production nonce CSP; no `unsafe-inline` or
  `unsafe-eval` production escape. Test hydration and offline navigation.
- **Mobile** (`apps/mobile`): Expo/React Native for iPhone and iPad.
  Preserve the app, extension and App Group ids (D1), iOS/iPadOS 26
  minimum (D7), URLs, settings and App Store record. Use local native
  development/release builds. Expo Go cannot prove extension parity.
  Small native modules/config plugins may bridge widgets, notifications,
  App Intents, storage migration and signing; they contain no second
  engine. Generated native projects are not hand-maintained sources.
- **Storage**: server PostgreSQL through server-only Drizzle TypeScript
  schema and committed generated SQL migrations in `packages/db`.
  Generate, review, migrate; never push schema directly in production.
  Clients never import the DB package or connect directly to Postgres.
  Local Expo SQLite and browser IndexedDB preserve offline behavior;
  they do not replace or expose the server DB.
- **Data boundaries**: at 1.0 PostgreSQL stores public compiled catalog
  data and migration metadata only (D39). Reader data stays local and is
  never required for SSR. Clients call Next APIs for public catalog
  delivery and later explicit-consent sync/auth; the same engine computes
  locally offline. No personal data in URLs or logs, except the later
  secret revocable calendar-feed credential (handled as a credential).
  Logs retain method,
  route pattern, status and duration only, including proxy logs.
- **Accounts and optional stack**: Better Auth with Drizzle/Postgres is
  the Phase 14 choice, preserving D8's optional passkey/recovery rules.
  Do not add accounts now. Stripe waits for an approved billing need.
  D23 excludes the Vercel AI SDK and all model features. Tauri waits for
  a justified desktop client; Expo Android stays behind D6 after 1.0.
- **Toolchains/dependencies**: pin compatible supported Node/npm,
  Next/React, Expo/React Native, Postgres and build tools; commit one npm
  workspace lockfile. Review licenses, advisories, telemetry and native
  compatibility. E32 approves the requested stack in principle; record
  exact packages and real additional choices before adding them.
  No analytics, advertising, tracking, remote fonts, CDN code,
  session replay, crash-reporting services or SDKs that phone home.
  Disable framework/tooling telemetry and do not require hosted EAS/OTA.
- **Calendar rules** live only in the TypeScript catalog compiler.
  Church-year and lectionary rules are evaluated at compile time;
  the engine looks up dated appointments.
- **Catalog**: plain-text sources in `catalog/` compile to a deterministic,
  versioned release artifact, bundled for mobile/offline and imported
  transactionally into Postgres. Never edit the artifact/DB in production.
  All existing rights/review/reference/coverage checks survive the port.
  Reader data never goes in a public catalog.
- **Journal**: append-only events with UUIDv7 ids; deterministic fold,
  idempotent writes and undo as an event. Delete only for a reader's own
  deletion request. Its implementation is still P5/P8, not a migration
  shortcut through server state.
- **Dates**: civil dates for days, never JavaScript `Date` instants used
  as plan days. Resolve today at the device edge once; reminders use
  wall-clock times and an IANA zone. No server-zone default.
- **Tests**: port the current Swift test vectors before retiring their
  oracle. Shared cases run in Node on macOS/Linux and in browser/mobile
  runtimes; integration tests use real PostgreSQL, production Next
  standalone output and Expo builds. Table-driven engine cases,
  source-citing calendar golden tests and a test for every bug.
- **Design/accessibility**: Morning in docs/design.md and
  design/tokens.json generates Tailwind/shadcn CSS and React Native
  tokens. Change tokens first and commit outputs. No raw colors or
  replacement artwork. shadcn DOM components are web-only. Dynamic Type
  through AX5, VoiceOver, Reduce Motion, light/dark contrast on mobile;
  WCAG 2.2 AA, keyboard and 320px/zoom checks on the web. States always
  have words or symbols; color alone never carries their meaning.
- **Browsers** (D30): current and previous Safari, Chrome, Firefox and
  Edge, desktop/mobile. Public plan pages are server rendered; older
  browsers receive a plain notice.
- **Serving**: Docker Compose from clean origin/main releases under
  `/srv/www/daybyword.com`. Planned source files:
  `deploy/compose.yaml`, `deploy/Dockerfile`,
  `deploy/caddy/daybyword.com`; host site file
  `/etc/caddy/sites/daybyword.com`. Inspect the actual host first.
  Project name `daybyword`; Node container port 3000 maps only to
  `127.0.0.1:4316` (verify free). DB `daybyword`, runtime role
  `daybyword_app`; Postgres 5432 stays private to the Docker network,
  with no production host port. No second proxy or platform dashboard.
- **TLS/backups**: keep host Caddy; prefer its Cloudflare DNS module and
  a zone-scoped token, with Cloudflare Full (strict) when proxied.
  Missing shared modules/account settings require coordination under
  D34, not changes to other projects. Nightly `pg_dump`, encrypted
  off-server copies, retention and an isolated restore drill begin with
  the first Postgres deploy, even before accounts.
- **Secrets**: root-owned mode-600 `shared/env` on the server, protected
  Caddy environment for DNS credentials, never images or public bundles.
  Never commit .env files, signing keys/profiles/certificates or the
  legacy `apple/Config/Secrets.xcconfig`. Public-prefixed Expo/Next
  variables cannot contain secrets.
- **Formatting/localization**: shared typed interface strings, English
  first, and extension resources where needed. Phase M pins JS/TS/CSS
  format/lint rules and replaces the Swift-only gates without weakening
  checks. Keep source provenance for the numeric scripture datasets.
- **Project code**: write fresh code that reads like its surroundings,
  with abstractions proportionate to a real need. Copy no code, scripts
  or content from the owner's other repositories (D22).

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
- **Editions and calendars are labeled exactly** (Research finding
  7). Daily Office readings are never confused with Sunday or Communion
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

1. `make check` passes. Until PM.2 this is the existing Swift gate.
   During migration it covers retained legacy targets and their replacements;
   PM.11 leaves the new-stack gate in docs/stack-migration.md as the sole
   default. It covers toolchains, format/lint/types/imports, tokens/contrast,
   catalog integrity, shared-engine, real DB/API and mobile unit tests,
   and interface strings. Touched targets build with zero warnings.
2. User-visible work is seen working once, where it runs: mobile work in
   an Expo native development build in the iOS Simulator (use the legacy
   simulator script until PM replaces it), with
   VoiceOver labels on new controls; web work in a real browser with
   `make serve`, with the console free of errors and CSP violations.
   Widgets, notification actions, and App Intents are exercised where they
   run, not only in unit tests. Do not commit routine screenshots.
3. Engine changes have their cases, written before the code.
4. Plan content meets its review level, its claims are verified by the
   compiler, and its rights entry is `cleared`, or the plan stays out of
   release builds.
5. Server changes that are deployed pass `make check-live`, and the owner's
   other sites still answer as before.
6. The documents the item changes are updated, briefly.
7. The BUILD.md box is ticked in the same commit as the work.

**At each milestone, and before every TestFlight build or deploy**, run
`make check-full` (`make check`, the web tour in light and dark at desktop
and narrow widths, the app tour in light and dark, and the shared
TypeScript/compiler, Node server and PostgreSQL on Linux after migration;
keep the legacy checks until replaced). Check by hand what the tours
cannot: a phone width and 200% text on the web, one large Dynamic Type
size, and dark mode in the
new screens. Fix what it finds before shipping.

Never claim verification you did not perform. If a step could not be run (no
network, a missing tool, no device), say so in the commit body and the
Handoff notes instead of ticking the box.

## 8. Commits

- One commit per completed BUILD.md item, or one for a group of related
  items finished together. Use an imperative subject of 72 characters or fewer that starts
  with the step id, for example
  `P5.5: Keep the next unread reading next at the reader's pace`. The body
  says what changed and why.
- Pull with `--ff-only` before starting, and never force-push `main`.
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
  document, or `catalog/SOURCES.md`. The Handoff notes and the "Current
  state" line are replaced each session, never appended to.
- **What stays in BUILD.md while it guides future work:** "How agents use
  this file", the finished-product definition, the product principles, the
  Owner decisions table, the Engineering foundations, the Build status
  table, and the Handoff notes. The research findings are in
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
Node/npm, Docker/Compose, Expo and Apple build tools, and user-local tools.
Prefer well-known, maintained tools from their official sources, and record in README.md's
prerequisites any tool a script or `make check` depends on. This does not
cover `sudo`, macOS system or security settings, paid software, or adding a
package dependency (§5 and `docs/decisions.md` govern that).

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
