# Working on Day by Word

Day by Word is a Bible reading companion: a native iPhone and iPad app built
in SwiftUI, and a web version at daybyword.com served by a Swift server
(Hummingbird 2) on the owner's own machine. It helps Christians choose a
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
   research findings, the Owner decisions table (D1–D38, all answered by the
   owner on 2026-10-30), the Engineering foundations, and the Handoff notes
   at the bottom.
2. Read `docs/decisions.md` (once it exists) and any document linked from
   the items you are about to work on: `docs/engine.md` for engine work;
   `docs/catalog-format.md`, `docs/editorial.md`, and `catalog/SOURCES.md`
   for plans; `docs/product.md` and `docs/design.md` for anything a reader
   sees; `docs/deploy.md` before touching the server.
3. Run `git status`, `git log --oneline -20`, and `make check` (once it
   exists), so you know the real state before trusting any checkbox.

The owner (GitHub `dunamismax`) decides the product. In anything this
project publishes, refer to the owner only as the owner, and never attribute
a church, tradition, or faith story to them.

## 2. The session loop

1. Find the **first unchecked `- [ ]` item in the earliest phase that is not
   complete**, skipping items whose gate is still closed and [OWNER] steps
   still waiting on the owner (§4). The one exception is the design session
   (BUILD.md P2.3), which is a hard stop: once its mockups are shown, wait
   for the owner to finalize the design, and build nothing else until the
   owner says it is final. Phases are ordered, and items inside a
   phase are ordered unless marked *(parallel-safe)* or the phase says
   otherwise. Phase 10 (the launch catalog) may run alongside Phases 9–17.
2. Inspect the relevant code before writing any. Checkboxes can drift from
   reality: if an item is already done, verify it and tick it; if a ticked
   item is broken, untick it and say why in the Handoff notes.
3. Implement the item completely, in the app and on the web together
   (D37): code, tests, docs, and verification.
4. Verify it (§7), and tick the box only when it meets the definition of
   done.
5. Commit (§8), then take the next item. Complete as many items as you can
   in one session, and stop only at the end of your budget. When you meet a
   blocker, clear it or work around it, record why, and keep going.
6. Before ending: make sure `make check` passes, push, update the Build
   status table in BUILD.md, and **replace** the Handoff notes with the
   current state (what you finished, what is half-done, what is blocked, and
   anything surprising). Keep them under 25 lines; history lives in Git.

Never leave `main` broken. If you must stop mid-item, either finish it to a
passing state or revert the partial work, and record it in the Handoff
notes.

If an item is wrong, too large, or out of order, do not silently skip or
delete it. Split it into sub-items (`P5.6a`, `P5.6b`), rewrite it, or add a
dated note under it, and say what you changed in the Handoff notes.

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
  sensitive, and in some laws they are special-category data (BUILD.md
  Research finding 11). They are private by default, kept on the device
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
engineering. The owner's answers in D1–D38 are the product's direction. An
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

BUILD.md's Engineering foundations summarize these, and `docs/decisions.md`
records each decision with its reasons.

- **One engine, everywhere.** `Packages/ReadingEngine` (references,
  schedules, progress, reminder rules) is the single implementation of the
  reading logic. The app, the widgets and other extensions, the server, and
  the catalog compiler all use it. No app view, server route, JavaScript
  module, or SQL query reimplements engine logic; the web's JavaScript asks
  the server. Change `docs/engine.md` and add a case first, then the code.
- **Packages** (`Packages/`): `ReadingEngine`, `ReadingData` (the SQLite
  wrapper, the catalog reader, the journal, the sync client), and
  `CatalogCompiler` (the `catalog` tool) use Foundation only, build on
  Linux, and are tested on macOS and on Linux. The server runs them on
  Linux, and both platforms must give the same answers.
- **Apple app** (`apple/`): Swift 6 language mode with complete concurrency
  checking, SwiftUI, Observation (`@Observable`), WidgetKit, App Intents,
  UserNotifications, and the system `SQLite3`. Xcode 27 and the iOS 27 SDK,
  with iOS 26 as the deployment target (D7). The project is generated from
  `apple/project.yml` by XcodeGen: never hand-edit `*.xcodeproj`, and run
  `make generate`. The app target holds UI and composition only.
- **Server** (`Server/`): `DayByWordServer` on Hummingbird 2 (D5), with
  SQLite through `ReadingData` and WAL mode. It renders semantic HTML on the
  server, serves the project's own JavaScript and CSS, and provides the sync
  API. Check current official documentation (through Context7 where
  available) before relying on a Hummingbird or Swift API you have not used
  in this repository.
- **The toolchain is pinned** in `.swift-version` and used everywhere: this
  Mac, CI, and the server. Change it in one commit with `make check` green
  on both macOS and Linux.
- **Calendar rules live only in the compiler.** Church-year and lectionary
  rules are evaluated at compile time in `CatalogCompiler`, and the engine
  looks dated appointments up. Never reimplement a lectionary rule anywhere
  else.
- **The catalog** is compiled from `catalog/` (`make catalog`) into a
  read-only database. It is never edited in place or in production, and
  reader data never goes in it.
- **The journal is append-only.** Every reader action is an event with a
  UUIDv7 id. State is a deterministic fold, and undo is an event. Never
  mutate or delete events, except to carry out a reader's own deletion
  request. Writes are idempotent, so retries never double-count.
- **Dates are civil dates.** Plans, enrollments, and events speak in
  `CivilDate`, never a Foundation `Date` standing for a day. The reader's
  "today" is resolved once, at the edge, from their device's time zone.
  Reminders are wall-clock times with an IANA zone.
- **Tests**: Swift Testing for the packages, the server (with
  HummingbirdTesting), and the app's unit tests; XCTest for UI tests;
  browser tests through WebDriver for the web (a decision entry records the
  client). Every engine rule has table-driven cases. Every calendar and
  lectionary rule has a test citing its source, with golden files across
  years. Every bug gets a test.
- **Dependencies**: zero third-party runtime dependencies in the Apple app;
  the approved build tools are XcodeGen and Apple's `swift format`. The
  server may use Hummingbird 2 and the Swift Server Work Group packages it
  brings; any other package needs a decision entry first, and every package
  is pinned. The web's JavaScript is the project's own vanilla ES modules,
  with no npm, no bundler, and no third-party scripts. Never add analytics,
  advertising, tracking, crash-reporting, session-replay, affiliate,
  remote-font, or CDN code, any SDK that phones home, or any AI model or
  service (D23).
- **Nothing from elsewhere.** A strict Content Security Policy: no remote
  fonts, scripts, styles, images, or frames. Links out are fine; loads from
  elsewhere are not.
- **Modern browsers** (D30): the current and previous major versions of
  Safari, Chrome, Firefox, and Edge, desktop and mobile. The web app may
  require JavaScript, older browsers get a plain notice, and pages stay
  semantic and accessible. Public plan pages are rendered on the server.
- **Offline first in the app.** Everything except sync works in airplane
  mode. The web caches the active plans and queues marks made offline.
- **Personal data** (D10): kept on the device by default, and on the server
  only after explicit consent. Server logs never record passages, plans, or
  reading events; log request metadata only. Never put personal data in a
  URL. The one exception is the secret, revocable calendar-feed token,
  which is a credential and is handled as one.
- **Design**: follow `docs/design.md` and `design/tokens.json`. Use the
  generated color assets and CSS custom properties, never raw colors.
  Change a token first, regenerate, and commit both.
- **Accessibility**: Dynamic Type through AX5, VoiceOver, Reduce Motion, and
  sufficient contrast in light and dark on Apple platforms; WCAG 2.2 AA on
  the web. Color is never the only carrier of meaning: assignment states
  always have words or symbols too.
- **Serving**: only a release built from `origin/main` is served
  (`docs/deploy.md`). The checkout and the repository are never a web root.
- **Secrets**: never commit `.p8` keys, certificates, provisioning profiles,
  `apple/Config/Secrets.xcconfig`, VAPID private keys, server environment
  files, or `.env` files. Server secrets live in `shared/env` on the server
  (root-owned, mode 600), never in the app binary or a web page.
- **Formatting**: `swift format` with the repository's `.swift-format`
  (linted by `make check`); JavaScript and CSS follow `docs/web.md`.
- Write code that reads like the surrounding code, and keep abstractions in
  proportion to a real need. Everything here is written fresh (D22): never
  copy code or scripts from the owner's other repositories.

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
- **Editions and calendars are labeled exactly** (BUILD.md Research finding
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

1. `make check` passes: formatting, the catalog compile and integrity suite,
   the package tests, the server tests, the app's unit tests, the browser
   tests as they arrive, and the link check. The packages and server also
   pass on Linux, through `make test-linux` where a container runtime is
   present and otherwise at the next deploy or CI run, which the Handoff
   notes say. The build has zero warnings in the touched targets.
   xcodebuild prints warnings only for files it recompiles, so touch the
   sources or clean before trusting that.
2. User-visible Apple work is exercised in the iOS Simulator: launch it,
   drive the flow, and capture a screenshot. Check light mode, dark mode,
   one large Dynamic Type size, and VoiceOver labels on new controls. Pick
   the device with `scripts/sim-destination.sh`, never a hard-coded one.
   Widgets, notification actions, and App Intents are exercised where they
   run, not only in unit tests. Do not commit routine screenshots.
3. User-visible web work is exercised in a real browser (the in-app browser
   or Chrome) with `make serve` running: a desktop width and a phone width
   (the browser's mobile emulation), light and dark, and 200% text. Check
   the console for errors and CSP violations.
4. Engine changes have their cases, written before the code.
5. Plan content meets its review level, its claims are verified by the
   compiler, and its rights entry is `cleared` for where it is served, or
   the plan stays out of release builds.
6. Server changes that are deployed pass `make check-live`, and the owner's
   other sites still answer as before.
7. Relevant docs (`README.md`, `docs/*.md`, `catalog/SOURCES.md`) are
   updated.
8. The BUILD.md box is ticked in the same commit as the work.

Never claim verification you did not perform. If a step could not be run (no
network, a missing tool, no device), say so in the commit body and the
Handoff notes instead of ticking the box.

## 8. Commits

- One commit per completed BUILD.md item, or a tight group of related
  items. Use an imperative subject of 72 characters or fewer that starts
  with the step id, for example
  `P5.5: Keep the next unread reading next at the reader's pace`. The body
  says what changed and why.
- Pull with `--ff-only` before starting, and never force-push `main`.
- The repository is public (D4), so every push publishes. Never commit
  secrets, correspondence, readers' personal data, or anything a licence
  forbids publishing.
- Keep documentation current and useful: update the owning document in
  place, and keep history in BUILD.md's notes, the decision tables, and Git,
  as BUILD.md's "How agents use this file" describes.

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
Swift toolchains through swiftly, and user-local tools. Prefer well-known,
maintained tools from their official sources, and record in README.md's
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
