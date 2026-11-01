# BUILD.md: The Build Plan

This is the master plan for **Day by Word**, a Bible reading companion: a
native iPhone and iPad app built in SwiftUI, and a web version at
[daybyword.com](https://daybyword.com) served by a Swift server on the
owner's own machine. AI agent sessions build it step by step, working under
[AGENTS.md](AGENTS.md).

> **Day by Word.** Your Bible reading companion.
> *Find your plan. Read your Bible. Keep your place.*

**Name:** **Day by Word** (owner decision D1). The canonical domain is
**daybyword.com**, registered by the owner at Cloudflare on 2026-10-30. The
repository is `dunamismax/daybyword` (public, all rights reserved, D4). The
support address is **support@daybyword.com** (D28). Another party runs an
unrelated Bible reading plan site called "DayByWord" at daybyword.org; the
owner has chosen to keep the name (D2).

**What it is.** Day by Word helps Christians choose a Bible reading plan,
know what to read today, and keep a trustworthy record of their reading.
People keep reading in their own physical Bible, preferred Bible app, or
audio service. Day by Word supplies the structure: a curated plan catalog,
personal scheduling, reminders, progress, and a welcoming way to resume
after an interruption. It never shows Bible text itself (D13). The central
problem it solves is decision fatigue: someone who struggles to choose a
passage may struggle just as much with a catalog of 500 plans. So Day by
Word recommends a few suitable plans, explains the differences, and makes
the first reading easy to begin. The catalog supports that experience; it
never becomes the experience.

**First audiences.** People who already want to read Scripture but find
planning and consistency hard, above all readers of physical Bibles and
readers drawn to historic prayer-book patterns. Churches, families, and
Christians of every tradition come after the core experience works.

**The founding brief.** This plan comes from the owner's concept document
(*Bible Reading Companion Concept*, 2026-10-30) and from the owner's answers
to every open decision on the same day. It carries the brief's substance:
the product, the three schedule behaviors, the catalog standard, the
permissions research, and the first release. Where the owner decided
differently from the brief (for example, building straight to version 1.0
without interviews or a pilot, D25), the decision says so. Where this file
and the brief differ, this file is current.

**No denominational affiliation.** Day by Word is an independent Christian
project. It serves readers of every tradition, describes each tradition's
plans in neutral language, and speaks for no church, denomination, ministry,
or publisher. It has no SOUL.md and takes no side on questions Christians
dispute (AGENTS.md §3).

---

## How agents use this file

1. Read AGENTS.md first. Then read this whole file once per session. It
   holds only the plan to version 1.0 (D39); the research findings are in
   [docs/research/findings.md](docs/research/findings.md), the feature map
   in [docs/research/competitors.md](docs/research/competitors.md), and the
   work after 1.0 in [docs/roadmap.md](docs/roadmap.md). Read those only
   when an item points there.
2. Work the **first open `- [ ]` item in the earliest incomplete phase**,
   skipping items whose gate is still closed and items marked [OWNER] that
   are waiting on the owner personally (AGENTS.md §4). Items marked
   *(parallel-safe)* may be done in any order within their phase, and Phase
   10 (the launch catalog) may run alongside Phases 9–17.
3. Build the smallest thing that meets the item well. If an item asks for
   more than 1.0 needs, rewrite it smaller and move the rest to
   docs/roadmap.md's Phase 28 with a note, rather than building it now.
4. A feature that exists on both the app and the web lands on both within
   the same milestone (D37, as D39 revised it).
5. Inspect the code before trusting a checkbox. Fix drift in either
   direction.
6. Tick a box only when AGENTS.md §7 (definition of done) is met. Commit the
   tick with the work, with the step id in the subject (for example
   `P5.5: ...`); related items may share a commit.
7. Complete as many items as you can in a session. Before stopping, run
   `make check`, update the **Build status** table, push, and replace the
   **Handoff notes** at the bottom. Run `make check-full` at each milestone
   and before every TestFlight build or deploy.
8. If an item is wrong, too large, or out of order, do not silently skip or
   delete it. Split it, rewrite it, or move it to the roadmap with a note,
   and say what you changed in the Handoff notes.
9. Record history briefly where the next agent will look for it: a short,
   dated *Note* or *Result* line under the item, a decision entry only for a
   real choice, evidence in `catalog/SOURCES.md`, and the current state in
   the Handoff notes. Git keeps the rest.
10. When every item in a phase is ticked, move the whole phase to
   [BUILD-HISTORY.md](BUILD-HISTORY.md) in the same commit, leaving its
   heading and a one-line pointer here (AGENTS.md §8).

Agents do every item themselves (D3). The markers describe the kind of work:

- **[OWNER]**: a step only the owner can take: signing in to the owner's own
  accounts (Cloudflare, Codeberg, payments), the owner's own review or
  choice, supplying images, or confirming a message sent in the owner's
  name. Agents prepare everything around it.
- **[GATE Dn]**: depends on decision Dn opening later (D6 for Android, D11
  for paid features).
- **[RIGHTS]**: needs cleared entries in `catalog/SOURCES.md`.
- **[REVIEW]**: editorial or expert review of plan content, or of anything
  describing a tradition (`docs/editorial.md`).
- **[GATE DEMO]**: begins once the first usable build is on TestFlight and
  at daybyword.com (P8.14).

---

## Build status

Update the **Done** column whenever you tick or untick a box. "Items" counts
top-level items; sub-items roll up into their parent. D39 (2026-11-01)
trimmed the path to 1.0 from 148 open items to 103.

| Phase | Name | Milestone | Items | Done |
|---|---|---|---|---|
| 0 | Owner foundations | — | 6 | 6 |
| 1 | Repository and toolchain | M1 Foundation | 13 | 13 |
| 2 | Product, design system, and shells | M1 Foundation | 12 | 12 |
| 3 | Scripture references | M1 Foundation | 8 | 8 |
| 4 | The catalog | M1 Foundation | 8 | 3 |
| 5 | The reading engine | M1 Foundation | 11 | 0 |
| 6 | Church calendars and lectionaries | after 1.0 (roadmap) | — | — |
| 7 | Hosting at daybyword.com | M1 Foundation | 6 | 0 |
| 8 | First light | M2 First light | 14 | 0 |
| 9 | Choosing a plan | M3 Version 1.0 | 5 | 0 |
| 10 | The launch catalog | M3 Version 1.0 | 9 | 0 |
| 11 | Progress and history | M3 Version 1.0 | 5 | 0 |
| 12 | Widgets and Apple integration | M3 Version 1.0 | 4 | 0 |
| 13 | Paper and calendars | M3 Version 1.0 | 3 | 0 |
| 14 | Accounts, backup, and sync | after 1.0 (roadmap) | — | — |
| 15 | The web app: install and offline | M3 Version 1.0 | 5 | 0 |
| 16 | Public pages, legal, and App Store readiness | M3 Version 1.0 | 9 | 0 |
| 17 | Quality hardening | M3 Version 1.0 | 9 | 0 |
| 18 | Version 1.0 launch | M3 Version 1.0 | 9 | 0 |
| 19–28 | After 1.0 | roadmap | — | — |

**Current state (2026-11-01):** Phases 0, 1, and 2 are finished and moved
to [BUILD-HISTORY.md](BUILD-HISTORY.md). Build 25 is on TestFlight and
installed on the owner's iPhone. In Phase 3 the book registry (P3.1) and
the English versification (P3.2) are done. The owner approved a leaner
path to 1.0 (D39). **Next: P3.3.** Nothing is deployed yet.

---

## The finished product

This section defines what "complete" means. Version 1.0 delivers it with
Day by Word's own plans, kept on the device and in the browser (D39); the
paragraphs marked *after 1.0* come later, from [docs/roadmap.md](docs/roadmap.md).
When the whole plan is done, Day by Word is:

**A plan you chose with confidence.** A few practical questions come first:
what you hope to read, how much time feels realistic, which days you expect
to read, and whether you want to follow a church calendar. Tradition and
Bible edition are optional, with "not sure" always an answer. Three suitable
plans follow, each with a concrete reason, a sample week, and an honest
workload, side by side. Someone who already knows their plan can search and
start in seconds. No account is needed.

**Today, at a glance.** One screen holds the next reading and its plan
("Gospels at your pace — Reading 12"), the passage references set large
enough to read from across a desk, and three controls: **Open in my Bible
app**, **Copy reference**, and **Mark read**. Marking takes one deliberate
tap, and undoing it takes one more. The same reading appears on the Lock
Screen, on the Home Screen, in the reminder itself, and on the web.

**Your Bible, not ours.** Day by Word never shows Bible text. Paper Bibles
are first-class: a physical Bible mode, weekly printable checklists, and
large print. Digital readers go straight to the passage in tested Bible
apps and websites (YouVersion at launch, more after, D26), and every reading
has a copy-reference fallback. Day by Word never treats opening a link as
proof that a passage was read; the reader confirms.

**Schedules that understand the plan.** There are three behaviors, *Continue
at my pace*, *Work toward a finish date*, and *Follow the calendar*, each
explained in plain words and suited to the plans it fits. They are never
confused with one another: an ordinary 365-reading sequence moves forward
after a holiday, and Easter readings stay at Easter.

**Coming back is normal.** After missed days the reader is welcomed back and
offered real choices: continue from the next unread passage, spread the
outstanding readings within a limit they set, or rejoin today's calendar.
Each choice is previewed before anything changes. History is never
rewritten, and a skip is a scheduling decision, not a reading.

**A catalog people can trust.** Every plan gives its exact title and
edition, creator or source, a sample week, a realistic workload, and
precisely stated coverage: the whole Bible, selected books, or a recurring
cycle, with repeats, optional passages, and omissions shown. Limitations sit
beside advantages, and each plan has a readable source note. The selection
criteria are published, and every item has a permissions record. *After
1.0:* historic plans and prayer-book lectionaries, computed correctly from
their own rules, edition by edition, with the rule behind today's readings
shown.

**Honest progress.** The reader sees assignments completed, recent reading
days, books explored, and the next reading. Plan completion is kept apart
from Bible coverage. A streak is available for those who want one and is
never in charge. Returning after a gap, finishing a book, and keeping a
rhythm you chose are each celebrated quietly.

**Private and yours.** There are no ads, analytics, tracking, or AI features
(D12, D23). On the phone everything works without an account and offline,
the web keeps progress in the reader's browser, and export and deletion are
available at any time. *After 1.0:* optional backup and sync between the
app and the web, with passkeys.

**Quiet, readable, accessible.** Text is generous, Dynamic Type works up to
the largest sizes, and VoiceOver, dark mode, and keyboard use on the web are
all supported, to WCAG 2.2 AA. There is no feed, no ranking, and no
dashboard that reads like a performance review. Success can mean opening the
app for ten seconds and spending twenty minutes in the Bible.

**After 1.0.** Further work adds church calendars and historic plans;
accounts, backup, and sync; more Bible apps and websites to open
readings in; companion plans (for example a psalm beside the main plan),
with overlaps handled deliberately; reading logged outside any plan; church
and family plans joined by link or QR code, which encourage without
surveillance; a plan builder and private import; and more traditions and
languages as editorial expertise and rights allow.

---

## Product principles

`docs/product.md` (P2.1) expands these into rules for every screen.

1. **Choose with confidence.** Recommend a few suitable plans with reasons,
   and never lead with a wall of 500 plans.
2. **Read your own Bible.** Day by Word supplies structure and never shows
   Bible text; Scripture is read in the reader's Bible, app, or audio.
   Opening a link does not prove a reading; the reader confirms it.
3. **Returning is normal.** No guilt mechanics: no shaming, countdowns,
   leaderboards, or "you broke your streak" messages. A missed day is
   simply a day.
4. **The right schedule for the plan.** Sequential plans move, calendar
   plans keep their dates, and the difference is explained plainly.
5. **Honest records.** Completed, partial, skipped, and unread are distinct.
   Plan completion is not Bible coverage, and reading records describe
   activity; they cannot measure faithfulness, spiritual maturity, or
   understanding.
6. **Trustworthy content.** Every plan has a traceable source, verified
   references, transparent coverage, a realistic workload, clear
   instructions, a documented basis for reuse, and its limitations stated.
7. **Quiet and readable.** No social feed, no competitive rankings, no
   performance dashboard. Generous text, accessible controls, dark mode.
8. **Private by default.** Reading history and religious preferences are
   private, exportable, and deletable. Day by Word never advertises,
   tracks, or sells or shares data, and has no AI features.
9. **Works offline.** Active schedules and local progress are always
   available, and the app says clearly when backup is unavailable.
10. **Welcome every tradition.** Neutral, precise labels; no denominational
    affiliation; canon and calendar differences explained without ranking.
11. **Success is time in Scripture, not time in the app.** Never optimize
    for minutes spent in Day by Word.

### Information architecture

There are three destinations, the same on iOS and on the web, with
preferences in a secondary area (`docs/product.md`, P2.1).

| Section | Holds |
|---|---|
| **Today** | The next reading in each active plan, by session (morning and evening where a plan has them); its plan label; the references, large; Open in my Bible app, Copy reference, Mark read, and Undo; the welcome-back choices after a gap; rest days named as rest days |
| **Plans** | Recommendations; the catalog organized by goal (begin reading, the whole Bible, the New Testament, the Gospels, the Psalms, the church year, reading with a group) with filters (pace, length, reading days, morning and evening sessions, books included); search; plan pages; my plans (active, paused, finished) |
| **Progress** | Assignments completed, recent reading days, books explored, the next reading, history with late logging and undo, and an optional streak (D17) |

**Settings** (from a toolbar button in the app and the header on the web)
holds reminders, the preferred way to read and translation, book-name
convention (D29), appearance and text size, backup and sync, export and
deletion, sources and permissions, and about.

### The three schedule behaviors

Each plan declares which behaviors it permits. The reader chooses among
them, and the app explains them in ordinary language.

| Behavior | Suitable plans | What happens after missed days |
|---|---|---|
| **Continue at my pace** | Numbered or sequential plans | The next unread assignment stays next, and the projected finish date can move |
| **Work toward a finish date** | Flexible plans with a chosen deadline | Offer redistribution within a workload limit the reader sets, or a later finish date |
| **Follow the calendar** | Civil-date and liturgical schedules | Today's appointment stays on its proper date, and missed readings stay available in history |

**The rule that prevents the serious mistake:** moving an ordinary
365-reading sequence forward after a holiday is useful, but automatically
moving Easter readings to an unrelated week changes the nature of a
liturgical plan. A calendar plan may offer an optional personal adaptation
where its permissions allow, and the app always labels it as one.

**When a reader returns:** they are welcomed back and offered the relevant
choices: continue from the next unread passage, redistribute the
outstanding sequential readings, or rejoin today's calendar. The effect of
each choice is shown before it is applied. Rejoining a calendar never marks
older readings complete. Late logging, undo, and changes to reading days
never delete history. Pausing reminders on a calendar plan does not pause
the church calendar. Five-day plans make their rest days intentional. A
deadline plan shows its approximate workload before the reader accepts a
demanding target; if the target is unrealistic at the chosen pace, the app
offers a later date or a narrower plan and never hides the tradeoff by
quietly omitting readings.

---

## Owner decisions

The owner answered every decision on 2026-10-30 in an interactive session.
Under D3, agents may later record new decisions, or revise an answered one
only with strong evidence, as `(agent, date)` with their reasons. They never
reverse an owner's answer on product direction without asking.
Engineering consequences go in `docs/decisions.md`.

| ID | Question | Decision |
|---|---|---|
| D1 | Name and identifiers | **Day by Word** at daybyword.com, tagline "Your Bible reading companion", line "Find your plan. Read your Bible. Keep your place." Bundle ID **`com.daybyword.app`**, with extensions under it (for example `com.daybyword.app.widgets`) and the App Group `group.com.daybyword.app`. Xcode project and scheme `DayByWord`; URL scheme `daybyword://`; server product `DayByWordServer` (owner, 2026-10-30). |
| D2 | The name, given daybyword.org (Research finding 2) | **Keep Day by Word, with no trademark search or legal review**; the owner accepts the risk (owner, 2026-10-30). Agents never contact daybyword.org's operators, and any claim that arrives goes to the owner. |
| D3 | Who builds and decides | **Agents, autonomously** (owner, 2026-10-30), as Beautiful Corner's D21: agents build everything, decide every open question (recorded as `(agent, date)` with reasons), and do every item, including server work (D34), deploys, TestFlight, and App Store Connect. The only limits are the host's safety rules (the owner's credentials, payments, and messages sent in the owner's name still need the owner) and honesty. Agents may install the developer tools the work needs on the owner's Mac (Homebrew formulae and casks, Swift toolchains through swiftly, user-local tools), but never use `sudo` or change system settings. |
| D4 | Repository visibility and license | **Public, all rights reserved** (owner, 2026-10-30): a `LICENSE` file says so (P1.2), and plans, data, and fonts keep their own rights. Every push publishes, so beta feedback stays anonymized and letter drafts stay generic. |
| D5 | Platforms and stack | **A native iPhone and iPad app in SwiftUI, and daybyword.com served by a Swift server built on Hummingbird 2, with SQLite** (owner, 2026-10-30). **One engine, written once in Swift** (`ReadingEngine`), is used by the app, its extensions, the server, and the catalog compiler. Hummingbird 2 was chosen over Vapor 4, and SQLite over PostgreSQL (owner). The recommendation at the time had been a Rails site with a second, Ruby engine; the owner chose one language. |
| D6 | Android | **The installable web app for now; decide on native Android after version 1.0** (owner, 2026-10-30). The options then are a native Kotlin app, or the Swift SDK for Android sharing `ReadingEngine` (Research finding 12). |
| D7 | Minimum iOS version | **iOS and iPadOS 26**, built with Xcode 27 and the iOS 27 SDK (owner, 2026-10-30). |
| D8 | Accounts | **Optional, with passkeys and one-time recovery codes**: no passwords, no email, and no third-party sign-in. The free core never needs an account (owner, 2026-10-30). On the web, adding a passkey turns a browser profile (D10) into an account. |
| D9 | Outbound email | **None at version 1.0** (owner, 2026-10-30). Support mail arrives through Cloudflare Email Routing (D28). |
| D10 | Where personal data lives | **On the device by default; on the server only after explicit, separate consent** ("Keep my plans and progress on daybyword.com"), because reading data can reveal religious belief (Research finding 11). This covers web browser profiles and sync (owner, 2026-10-30). A browser profile is keyed by a random secret in a first-party cookie, holds no name or email, and is deleted after 18 months without use, with notice on the page beforehand. Export and deletion are available at any time. No analytics, advertising, or tracking; nothing sold or shared; no third-party processors. Encrypted off-server backups (P7.5) expire on a published schedule. *Revised by D39 (owner, 2026-11-01): at 1.0 the web keeps progress in the reader's own browser and the server stores none; browser profiles on the server (P28.8) come with accounts after 1.0.* |
| D11 | Sustainability and pricing | **A free core forever, plus voluntary donations** (owner, 2026-10-30). Free means a useful plan selection, reading progress, ordinary reminders, backup and sync, and personal data export. Paid extras (family organization, advanced personal planning, church administration) are considered only after launch, if readers show they value them, and tested against the supporter model. No ads, ever; no lifetime price. |
| D12 | Measurement | **No analytics, ever** (owner, 2026-10-30). With no pilot (D25), learning comes from the beta (D36), support mail, the aggregate data Apple provides, and opt-in surveys (P18.9). |
| D13 | Bible text in the product | **Never** (owner, 2026-10-30): Day by Word never shows Bible text, now or later. It shows references and opens the reader's own Bible. Word counts from a public-domain text are used internally for workload estimates only. |
| D14 | The launch catalog | **All twelve plans** (owner, 2026-10-30), each subject to editorial and rights review (Phase 10): Gospels at your pace; the Bible in a year (canonical, balanced by reading time); the Bible in a year, five days a week; the New Testament in a year, five days a week; the Story of Scripture (about 50 readings introducing the biblical narrative); a psalm a day; Proverbs through the month; Paul's letters; the deuterocanonical books (for Bibles that include them); M'Cheyne's Calendar for Daily Readings (1842); the 1979 Daily Office Lectionary; and the 1662 Table of Lessons with its monthly Psalter. Not at launch: a chronological plan, contemporary ministry plans, the RCL, and the 2019 Daily Office (Phase 23). Never copy a contemporary publisher's version of a familiar plan because its underlying idea is old. The catalog must stay useful if any requested publisher declines. *Revised by D39 (owner, 2026-11-01): 1.0 launches with the eight original plans; M'Cheyne, the 1979 and 1662 plans, and the deuterocanonical books follow after 1.0.* |
| D15 | Prayer-book plans and their reviewers | **The owner reviews the 1979 and 1662 plans now, as reviewer of record, and a second reviewer who uses each book is sought when possible** (owner, 2026-10-30). Until the owner's review is recorded, those plans are marked "in review" and stay out of release builds. Each is labeled with its exact edition and calendar rule and kept apart from Sunday and Communion lectionaries. The later English tables (1871, 1922, 1961) are separate plans, never merged under 1662. *Revised by D39 (owner, 2026-11-01): the prayer-book plans come after 1.0, and their reviews with them.* |
| D16 | Territories | **The US App Store first; other storefronts after a rights review of every plan served there** (owner, 2026-10-30). The website serves everyone, and the 1662 UK question goes to Cambridge University Press (D38) before any UK storefront. No geo-blocking unless the rights research requires it; every plan page states its rights basis. |
| D17 | Streaks | **Opt-in, against the reader's own rhythm** (owner, 2026-10-30): off by default, counted against the reader's reading days (rest days never break it), shown small, never in notifications, and never with loss language. |
| D18 | Visual identity | **Chosen in a design session** (owner, 2026-10-30) from three directions agents draw (P2.3): **Bookmark** (paper, ink, a single ribbon color for "next", references in a book face), **Morning** (light and open, a modern sans, one dawn accent), and **Desk** (near-monochrome, very large references readable from across a desk). The owner picks or mixes them, and the choice is recorded here. The session is a hard stop: nothing further is built until the owner says the design is final (owner, 2026-10-30). **Chosen: Morning** (owner, 2026-11-01): the owner preferred it to Bookmark and Desk and asked for building to continue. `docs/design.md` and `design/tokens.json` record it. |
| D19 | Images and icons | **The owner supplies them** (owner, 2026-10-30). Agents never draw, redraw, or generate images or icons. They write prompts in `design/image-prompts.md`, the owner generates the files, and agents resize, export, and register them. **Batch exception (owner, 2026-11-01):** the owner requested creation and registration of the images in that brief. The delivered Morning assets are inventoried in `design/images/README.md`; future image work retains the standing workflow unless the owner requests otherwise. |
| D20 | Calendar and lectionary facts | **Facts only** (dates, names, ranks, references), never prose, each cited and cross-checked against two independent sources with every difference listed (owner, 2026-10-30). |
| D21 | Rights research downloads | **Agents may download** candidate scans and data (Internet Archive, HathiTrust, Google Books, eBible.org, CCEL, STEPBible-Data, first-party church and publisher sites) into the gitignored `research/` folder, and nothing there ships until it is cleared (owner, 2026-10-30). |
| D22 | Reuse from the owner's other repositories | **None: everything here is written fresh** (owner, 2026-10-30). No code, scripts, or content come from `prayerbook-atlas`, `beautiful-corner`, or any other repository of the owner's. Agents may read Prayerbook Atlas's public `docs/deploy.md` to learn the server's conventions (Research finding 14), so this site fits beside the others, but they copy nothing. A SOUL.md or statement of faith is never brought in. |
| D23 | Artificial intelligence | **No AI features, ever** (owner, 2026-10-30): no generative models, chat, or AI recommendations anywhere in the product. One exception, confirmed by the owner: private photo import may use Apple's on-device text recognition (Vision), which is not generative, runs only on the device, and shows every reference for the reader to confirm (P22.3). |
| D24 | Groups | **After version 1.0, private by default** (owner, 2026-10-30): churches publish a permitted plan with a join link or QR code; readers join the group's current day or start at the beginning where the plan allows; individual completion and notes are never visible to leaders by default. |
| D25 | Validation | **No interviews or pilot; build straight to version 1.0 and learn after launch** (owner, 2026-10-30). The brief had recommended 15–20 interviews and a four-week pilot. A short beta for bugs comes before release (D36), and the after-launch learning loop is P18.9. |
| D26 | Ways to read at launch | **Paper Bible mode, YouVersion and Bible.com, and Copy reference everywhere** (owner, 2026-10-30). Bible Gateway, ESV.org, Olive Tree, Logos, Blue Letter Bible, and audio services come after launch (Phase 19), each tested on a device first. Automatic sync with another app is promised only where a supported integration has been verified. |
| D27 | Hosting | **Self-hosted on ubuntu-vm, built on the server** (owner, 2026-10-30): each deploy builds a release from a clean copy of `origin/main` with the pinned Swift toolchain, runs it under systemd behind the shared Caddy, keeps SQLite in shared storage, and takes nightly encrypted off-server backups. No Docker. |
| D28 | Support email | **support@daybyword.com**, a Cloudflare Email Routing catch-all to the owner's inbox, receive-only (owner, 2026-10-30). |
| D29 | Book names, canon, and tradition labels | **Reader's choice** (owner, 2026-10-30). Book ids are USFM codes. Display names default to common English (Song of Songs, Sirach), and a setting offers other traditions' names (for example Song of Solomon, Canticle of Canticles, Ecclesiasticus). Every plan states the canon it assumes and the books it includes. Tradition labels are neutral and precise. Psalms show the plan's own numbering, with the other numbering beside it where they differ. |
| D30 | Web browsers | **Modern browsers only** (owner, 2026-10-30): the web app requires JavaScript and targets the current and previous major versions of Safari, Chrome, Firefox, and Edge, on desktop and mobile, and older browsers get a plain notice. Pages stay semantic and accessible (WCAG 2.2 AA), and public plan pages are rendered on the server so they can be found and shared. |
| D31 | Continuous integration | **Manual dispatch only** (owner, 2026-10-30); the local `make check` is the gate before every commit. |
| D32 | Codeberg mirror | **Yes** (owner, 2026-10-30): the owner creates `dunamismax/daybyword` on Codeberg and adds its push URL to `origin`, so one push updates both (P0.5). |
| D33 | Apple Developer account | **The owner's existing individual membership** (owner, 2026-10-30). The App Store shows the owner's own name as the seller. |
| D34 | Server access | **Standing permission** (owner, 2026-10-30): agents may SSH as root to `ubuntu-vm` to provision, deploy, back up, and maintain daybyword.com, provided they archive `/etc/caddy` before changing it, add only daybyword.com's own Caddy site file and edit no other, touch no other site or service, run deploys inside the server's shared deploy lock, and check the owner's other sites before and after every server change. *(Agent's reading, 2026-10-30, for the owner to correct if wrong: this also covers adding daybyword.com's own entry to `ubuntu-vm-backup` for off-server backups, and nothing else in that repository.)* |
| D35 | When daybyword.com starts serving | **Early, marked in development** (owner, 2026-10-30): deployed from Phase 7 on, with a quiet "in development" notice, `noindex`, and a `robots.txt` block until launch (P18.5). |
| D36 | A beta before release | **A short beta for bugs** (owner, 2026-10-30): a few weeks on TestFlight and the web with readers the owner invites, as a quality check, not a validation study (P18.3). |
| D37 | Build order | **The app and the web together** (owner, 2026-10-30): each feature lands on both in the same phase. *Revised by D39 (owner, 2026-11-01): a feature on both lands on both within the same milestone, not necessarily the same commit.* |
| D38 | Outside permissions | **Pursue all four once a usable build exists** ([GATE DEMO]; owner, 2026-10-30): Cambridge University Press (the 1662 tables in the UK), Anglican House (the 2019 Daily Office as a references-only schedule), the Consultation on Common Texts (the RCL and its daily readings), and partnership inquiries to ministries whose plans readers ask for (for example BibleProject and the Navigators), with no suggestion of existing agreement. Agents draft each letter, and the owner confirms it before it is sent in the owner's name. *Revised by D39 (owner, 2026-11-01): the letters concern plans that now come after 1.0, so they wait until those plans are being built (P8.15 and P8.16 moved to the roadmap).* |
| D39 | A leaner path to version 1.0 | **Approved by the owner in full, 2026-11-01**, after an agent's review found the plan sized for a larger product than 1.0 needs. (1) **First light** ships three original plans: Gospels at your pace, the Bible in a year, and Proverbs through the month (which exercises *Follow the calendar* by day of the month without church-year rules). (2) **The 1.0 catalog is Day by Word's own eight original plans** (P10.1–P10.7, P10.11). M'Cheyne, the 1979 and 1662 prayer-book plans, the deuterocanonical books, the church-year engine (Phase 6), and the D38 letters and D15 reviews they need follow after 1.0. (3) **Scripture work covers what those plans need**: English (KJV) versification, one strict reference format for plan files, verse sets, and word counts. Other canons' orders, other versifications, Psalm renumbering, and a parser for every citation style come later. (4) **The web at 1.0** renders public plan pages on the server and keeps each reader's progress in their own browser; the server computes with the engine from what the browser sends and stores nothing. Accounts, passkeys, backup, and sync (Phase 14) come after 1.0. (5) **The app and the web** stay one product, but a web counterpart may land later in the same milestone (D37). (6) **Two independent sources** (D20) are required for calendar and lectionary facts, as D20 says, and not for other facts such as book names. (7) **Process**: this file holds only the work to 1.0 (findings, the feature map, and later phases moved to `docs/`); `make check` is the per-commit gate and `make check-full` (the web and app tours, light and dark, and Linux) runs at milestones and before releases; related items may share a commit; and decision entries record real choices only (AGENTS.md §7, §8). |

---

## Engineering foundations

`docs/decisions.md` records each with its reasons (E1–E17 and after), and
README.md has the architecture and layout.

1. **One repository, one gate**: `make check` before every commit, and
   `make check-full` at milestones (D39).
2. **The plan, the enrollment, and the record are separate**: plans are
   versioned, enrollments record the version, and the journal records what
   the reader did (E2).
3. **An append-only event journal** with UUIDv7 ids, folded
   deterministically into state; undo is an event (E3).
4. **One engine, everywhere**: `ReadingEngine` is the only implementation
   of the reading logic, tested on macOS and Linux (E4).
5. **Calendars computed once, at compile time**, when church calendars
   arrive after 1.0 (E5).
6. **A compiled, versioned catalog** that refuses unverified references,
   false claims, and uncleared sources (E6).
7. **Civil dates, not instants**; "today" is resolved once, at the edge
   (E7).
8. **Local-first**: the app works offline without an account, and at 1.0
   the web keeps progress in the browser (E8, D39).
9. **SQLite everywhere**, through `ReadingData`'s own wrapper (E9, E18).
10. **Few dependencies**: none at runtime in the app; Hummingbird 2 and its
    packages on the server; the web's own vanilla JavaScript (E10, E20).
11. **Modern browsers, server-rendered pages, a strict CSP** (E11, E19).
12. **Shared design tokens** for the app and the web (E12, E23).
13. **Our own simple formats**: `key: value` front matter, tab-separated
    schedules, JSON registries (E13).
14. **A date override for tests**: `-today YYYY-MM-DD` and `?today=` (E14).
15. **Internationalized from the start** (E15, E25).

### Milestones

- **M1 Foundation** (Phases 1–7): the app and the server run in the chosen
  design; references, the catalog, and the engine are correct and tested;
  daybyword.com is deployed and marked as in development.
- **M2 First light** (Phase 8): Today, marking, reminders, the return flow,
  and three original plans, on TestFlight and at daybyword.com. This opens
  [GATE DEMO].
- **M3 Version 1.0** (Phases 9–18): choosing a plan, the eight-plan launch
  catalog, progress, widgets, print, the installable web app, legal pages,
  hardening, the beta, and launch.
- **After 1.0** ([docs/roadmap.md](docs/roadmap.md)): church calendars and
  historic plans, accounts and sync, more ways to read, companion plans,
  groups, the plan builder, more traditions and languages, the Watch, Mac,
  and Android, sustainability, and operations.

---

## Phase 0: Owner foundations

Finished; its items and notes are in [BUILD-HISTORY.md](BUILD-HISTORY.md).

## Phase 1: Repository and toolchain

Finished; its items and notes are in [BUILD-HISTORY.md](BUILD-HISTORY.md).

## Phase 2: Product, design system, and shells

Finished; its items and notes are in [BUILD-HISTORY.md](BUILD-HISTORY.md).

## Phase 3: Scripture references

Finished; its items and notes are in [BUILD-HISTORY.md](BUILD-HISTORY.md).

## Phase 4: The catalog

1.0's plans are all Day by Word's own (D39), so the catalog needs a simple
format, a compiler that checks every reference and claim, and an honest
sources registry. Per-use rights rules and external entries wait for
licensed plans (roadmap).

- [x] **P4.1** Give `catalog/SOURCES.md` its schema, kept to what is used: id, title, edition, creator or owner, where it was obtained, the basis for use (public domain, licence, or permission), attribution required, territories, what was checked, the date, and status (`cleared`, `pending`, `rejected`, `reference`). Add an entry for Day by Word's own original plans. *(Rewritten by D39.)*
  - *Result (agent, 2026-11-01):* the schema heads the file, machine-readable for the compiler (id from the heading, status from the Status line), and `daybyword-original` covers Day by Word's own plans.
- [x] **P4.2** Write `docs/catalog-format.md`: plan files with `key: value` front matter (id, title, version, summary, who it suits, schedule kind, permitted behaviors, reading days, coverage claim, books included, limitations, instructions, source note, rights id, review status) and a tab-separated schedule body in P3.4's reference format, and the rule for stable assignment ids. *(Rewritten by D39.)*
  - *Result (agent, 2026-11-01):* written, with an example plan. Schedules are `sequence` or `day-of-month`, the two 1.0 needs; `creator` was added for the plan page (P9.4).
- [x] **P4.3** The compiler (`swift run catalog`, called by `make catalog`): parse and validate `catalog/plans/`, verify every reference against the English scheme, and write a deterministic `build/catalog/Catalog.sqlite` with a schema version, a manifest, and a checksum. It fails on unknown sources, duplicate ids, unresolved references, and plans without a review status; release mode also fails on uncleared sources. *(Rewritten by D39: no search index at 1.0.)*
  - *Result (agent, 2026-11-01):* `PlanFile` reads and checks plan files with line numbers, `SourcesRegistry` reads SOURCES.md, and `CatalogBuild` writes `plans` and `assignments` with a content SHA-256 (our own, since CryptoKit is not on Linux) as schema 1 (docs/catalog-format.md). Release builds leave out plans below `reviewed`. The plan model is `Plan` in `ReadingEngine`.
- [ ] **P4.4** Claims checked against the facts: the compiler computes each plan's unique coverage, repeats, and omissions, and refuses a claim the schedule does not support. A "whole Bible" claim must cover every verse of its stated canon. The computed facts feed the plan page.
- [ ] **P4.6** Plan versions, simply: every plan file has a version, the catalog records it, and an enrollment records the version it follows. The full rules for corrections are P28.3, needed with the first correction after release. *(Rewritten by D39.)*
- [ ] **P4.8** Integration: `make catalog` feeds the app bundle (`apple/App/Resources/Catalog.sqlite`, gitignored) and the server (opened read-only from the release). A missing catalog fails clearly, and `make check` covers unique ids, resolved references, cleared sources, and no empty assignments.
- [ ] **P4.9** Write `docs/criteria.md`, the published selection criteria, in a page: verified references, transparent coverage, realistic workload, clear instructions, a documented basis for use, and limitations stated beside advantages. It becomes a public page in P16.5.
- [ ] **P4.10** Write `docs/editorial.md`, briefly: review levels (`checked`, automated validation passed; `reviewed`, an editorial review against the plan's rules and AGENTS.md §3; `expert`, a named reviewer's review, as D15 requires for prayer-book plans after 1.0), and the errata process for readers' reports.

## Phase 5: The reading engine

`ReadingEngine` is the only implementation (Engineering foundation 4). The
specification comes first, then the cases, then the code. It covers what
1.0's plans need; sessions and church-year schedules wait (roadmap).

- [ ] **P5.1** Write `docs/engine.md`, the specification, for what 1.0 needs: plan versions, assignments, enrollments, the journal and its event kinds, assignment states, the three behaviors, reading days and rest days, pausing, late logging, undo, partial completion, skips, the return choices and their previews, changing an enrollment, progress measures, and reminder rules. Each rule has a worked example and the plain wording the reader sees. *(Rewritten by D39.)*
- [ ] **P5.2** The case format and runner: table-driven JSON cases (catalog fixture, enrollment, events, today, expected output) in `ReadingEngine`'s tests, using invented plans with invented references and never a real plan's schedule. The same cases run on macOS and on Linux.
- [ ] **P5.3** `CivilDate`, written fresh (D22): weekdays, day arithmetic, the day of the month and of the year, and conversion at the edge to and from Foundation dates in a given time zone, with exhaustive tests. *(Rewritten by D39: the nth weekday and Julian Day Number come with Phase 6.)*
- [ ] **P5.4** The journal: event kinds, UUIDv7 ids, and a deterministic fold to state that gives the same result in any arrival order. Duplicate events are no-ops, and undo and redo are events. Cases cover a double tap, a retry, and recovery from an accidental completion.
- [ ] **P5.5** **Continue at my pace**: the next unread assignment is next; the projected finish follows the reader's recent pace and reading days; five-day plans keep rest days intentional; "ahead" and "behind" are stated neutrally, and only when useful.
- [ ] **P5.6** **Work toward a finish date**: the workload per reading day is computed before the reader accepts. Redistribution stays within a limit the reader sets and is previewed before it applies. An unrealistic target is met with a later date or a narrower plan, and readings are never silently omitted.
- [ ] **P5.7** **Follow the calendar** for civil-date schedules (a day of the month, as in Proverbs through the month, or a date in the year): today's appointment comes from the plan's dates; missed appointments stay in history as unread; rejoining marks nothing complete; pausing reminders never pauses the calendar. *(Rewritten by D39; church-year schedules are P28.4.)*
- [ ] **P5.8** **Return after a break**: detect a gap against the enrollment's reading days, then offer the choices that apply (continue from the next unread passage, redistribute outstanding readings, rejoin today's calendar), each with an exact preview. Applying a choice is an event.
- [ ] **P5.10** Changing an enrollment (reading days, start date, behavior) without deleting history, with the effect previewed first.
- [ ] **P5.11** Progress measures: assignments completed, recent reading days, books explored, and the next reading. Unique coverage counts each verse once and partly read chapters as partial, and plan completion is reported apart from coverage. The optional streak (D17) is measured against the reader's own reading days.
- [ ] **P5.12** Reminder rules: from enrollments, settings, the time zone, and the journal, compute the next fire times, honoring selected days, snooze, quiet hours, a maximum per day, stopping once the day's reading is marked, and the 64-request window (Research finding 9). Cases cover daylight saving changes and travel across zones.

## Phase 6: Church calendars and lectionaries

Moved to after 1.0 by D39 (2026-11-01); its items are in
[docs/roadmap.md](docs/roadmap.md).

## Phase 7: Hosting at daybyword.com

The site goes live early, marked as in development (D35). Agents provision
and deploy under D34's standing permission and its rules, and write every
script fresh, fitting the server's conventions (Research finding 14). At
1.0 the server stores no reader data (D39), so backups (P7.5) wait for
accounts.

- [ ] **P7.1** Write `docs/deploy.md`: `/srv/www/daybyword.com` with `releases/`, `current`, `shared/storage`, and `shared/env` (secrets such as the VAPID private key, root-owned, mode 600); the system user `daybyword`; a free port (4316 unless the server says otherwise; check first); the pinned Swift toolchain through swiftly in a system location; the systemd unit with filesystem protections; the Caddy site in `/etc/caddy/sites/` with www redirecting permanently to the apex; security headers; logs; and rollback.
- [ ] **P7.2** `make deploy` (`deploy/deploy.sh`): over `ssh root@ubuntu-vm`, inside the shared deploy lock, fast-forward the server's clone; build a candidate as an unprivileged user from a clean `git archive` of `origin/main` with the pinned toolchain (a release build, plus the package and server tests on Linux); compile the catalog in release mode; install the release; run the server's migrations; boot-check on a spare port; switch `current`; restart; check `/up`; and restore the previous release on any failure. The checkout is never a web root.
- [ ] **P7.3** Provision the server as `docs/deploy.md` says (D34): record how the owner's other sites answer, archive `/etc/caddy`, add the user, directories, toolchain, environment file, unit, and Caddy site beside the existing ones without editing any other, and check the other sites again afterward.
- [ ] **P7.4** The first deploy (after P0.4), then check every name: daybyword.com serves over HTTPS, www redirects permanently with the path kept, and the headers are right. Confirm that the owner's other sites answer exactly as before.
- [ ] **P7.6** A post-deploy check (`make check-live`): status codes, redirects, TLS, security headers, secure cookies, and no requests to other hosts. `make deploy` runs it and prints only failures.
- [ ] **P7.7** Until launch (P18.5): `robots.txt` disallows crawling, every page carries `noindex`, and a quiet line says the site is in development.

## Phase 8: First light

The first usable release: three original plans that exercise the three
behaviors (D39), in the app and on the web. Discover, preview, start, read
elsewhere, mark progress, receive a reminder, and return after a missed
day. Reliable reminders and quick logging matter more than a long feature
list.

- [ ] **P8.1 [REVIEW]** The first three plans compiled and reviewed, each Day by Word's own: **Gospels at your pace** (sequential, P10.1), **the Bible in a year** (canonical order, balanced by reading time; pace or finish date, P10.2), and **Proverbs through the month** (follow the calendar by day of the month, P10.7). Each has its full plan-page metadata. *(Rewritten by D39: the 1979 Daily Office moved to the roadmap.)*
- [ ] **P8.2** Starting a plan: a plain plan page with a sample week and workload; a start date, or "join today's reading" for calendar plans; the behavior, explained; reading days; how the reader reads (a physical Bible, YouVersion, or another app, with Copy reference); and a reminder offer. Notification permission is requested only after the reader chooses a reminder.
- [ ] **P8.3** Today: each active plan's next reading, with its label ("Gospels at your pace — Reading 12"), large references, **Open in …**, **Copy reference**, and **Mark read**. Rest days and finished days say so plainly, with no fanfare and no nagging.
- [ ] **P8.4** Marking: complete with one deliberate tap; mark part read ("part of it"); skip (labeled as a scheduling decision); log late for an earlier date; undo and redo. All of these are journal events.
- [ ] **P8.5** Opening a reading (D26): an adapter for YouVersion and Bible.com that builds the best link it can (the passage, or the chapter where that is the limit, said plainly) in the reader's chosen translation, opening the app where it is installed, and Copy reference everywhere. Test it on a device and record the date, app version, link format, and limits in `docs/destinations.md`.
- [ ] **P8.6** Physical Bible mode: references at the desk-glance size, a keep-the-screen-awake option, book and chapter called out for finding the place in print, and no link.
- [ ] **P8.7** The return flow over P5.8: a short welcome, the choices that apply with their previews, and a confirmation. History is never altered.
- [ ] **P8.8** iOS reminders over P5.12: local notifications in a rolling window; actions **Mark read**, **Snooze**, and **Open**, grouped by plan; an option to hide passage details on the Lock Screen; quiet hours; a maximum per day; pending requests removed when the day's reading is marked; rescheduling on time-zone change. Turning reminders off never limits the app.
- [ ] **P8.9** A small and a Lock Screen widget showing the next reading, with an interactive **Mark read** (an App Intent writing to the shared journal through the App Group) and an obvious way to undo in the app.
- [ ] **P8.10** The web: browse and preview plans; print a week's checklist; start a plan and use Today and marking, with progress kept in the reader's own browser and nothing stored on the server (D39). The browser sends its events with each request, and the server computes with `ReadingEngine` and keeps nothing, not even in logs. A plain page says what is kept where and how to export or clear it. *(Rewritten by D39; server-side profiles are P28.8.)*
- [ ] **P8.11** Offline: the app works fully in airplane mode. The web keeps Today and the coming week for the active plans, queues marks made offline with their event ids, and says clearly when it is offline.
- [ ] **P8.12** Progress, first version: assignments completed, recent reading days, and the next reading; a quiet welcome after returning from a gap.
- [ ] **P8.13** Settings, first version: reminders, the way to read and translation, book-name convention (D29), appearance, export of all personal data (JSON), delete all data, about, and version.
- [ ] **P8.14** Ship first light: an internal TestFlight build, and daybyword.com deployed with the three plans. Run `make check-full` first. This opens [GATE DEMO].

## Phase 9: Choosing a plan

With a catalog of eight plans (D39), choosing needs a short guided picker
and good plan pages, not search, filters, or comparison tables (roadmap).

- [ ] **P9.1** A short guided picker: three or four practical questions (what the reader hopes to read, realistic time, reading days), each skippable with "not sure", and a way to see every plan at once for readers who know what they want. *(Rewritten by D39.)*
- [ ] **P9.2** Recommendations: two or three suitable plans from simple, documented, tested rules (never popularity, and never AI, D23), each with a concrete reason tied to the reader's answers and its workload, with the caveat that estimates are approximate. *(Rewritten by D39.)*
- [ ] **P9.3** The plan list, grouped by goal (begin reading, the whole Bible, the New Testament, the Gospels, the Psalms and Proverbs). *(Rewritten by D39; filters are P28.5.)*
- [ ] **P9.4** The plan page: exact title and edition, creator or source, a short explanation, whom it suits, a sample week, schedule kind, expected workload, completion or cycle length, coverage (whole Bible, selected books, or a recurring set, with repeats, optional passages, and omissions), the tradition and books included in neutral language, limitations beside advantages, the source note, the review level, and the permissions in plain words.
- [ ] **P9.9** Public plan pages on the web as Day by Word's front door: clean URLs, honest titles and descriptions, structured data only where accurate, a sharing image from the owner's files (D19), and a sitemap.

## Phase 10: The launch catalog (parallel with Phases 9–17)

Each plan is Day by Word's own (D39), built from verse data and documented
rules, compiled, checked against its claims (P4.4), reviewed
(`docs/editorial.md`), and given complete plan-page metadata. M'Cheyne, the
prayer-book plans, and the deuterocanonical books follow after 1.0
(roadmap).

- [ ] **P10.1 [REVIEW]** **Gospels at your pace** (from P8.1): the four Gospels, 89 chapters, in readings sized by reading time.
- [ ] **P10.2 [REVIEW]** **The Bible in a year**, canonical order, balanced by reading time without splitting chapters unless the plan says so; permits pace and finish-date behaviors.
- [ ] **P10.3 [REVIEW]** **The Bible in a year, five days a week**, with rest days intentional.
- [ ] **P10.4 [REVIEW]** **The New Testament in a year, five days a week**: its 260 chapters, one a day.
- [ ] **P10.5 [REVIEW]** **The Story of Scripture**: a short introduction to the biblical narrative in about 50 readings. Its selection involves editorial judgment, which the plan page explains.
- [ ] **P10.6 [REVIEW]** **A psalm a day**: 150 readings, with Psalm 119 in sections if workload calls for it, in English (Hebrew) numbering, which the plan page states. *(Rewritten by D39; other numberings are P3.8.)*
- [ ] **P10.7 [REVIEW]** **Proverbs through the month**: 31 readings by day of the month, with the 31st handled honestly in shorter months.
- [ ] **P10.11 [REVIEW]** **Paul's letters**, in canonical order, with an optional arrangement in an order the plan page explains and labels as one view among several.
- [ ] **P10.13** The catalog review: every launch plan at `reviewed`, every claim verified, every rights entry `cleared`, and the criteria page current. Plans that are not ready wait; the catalog launches with what is ready.

## Phase 11: Progress and history

- [ ] **P11.1** The Progress screen: assignments completed, recent reading days (a plain week strip, never a heat map of performance), books explored, and the next reading.
- [ ] **P11.2** Quiet celebrations of returning after a gap, finishing a book, finishing a plan, and keeping a rhythm the reader chose: words, not confetti, and never a comparison with anyone else.
- [ ] **P11.3** The optional streak (D17): off by default, measured against the reader's reading days, small, and never mentioned in notifications.
- [ ] **P11.4** Coverage: unique verses read, by book, with partly read chapters shown as partial. Repeats never inflate it, and it is kept apart from plan completion.
- [ ] **P11.5** History: every assignment's state and every change, late logging, undo, and an archive of finished and paused plans.

## Phase 12: Widgets and Apple integration

- [ ] **P12.1** The App Group and the capabilities the extensions need, registered through Xcode's automatic signing on the owner's account (D33).
- [ ] **P12.2** Widgets: small (the next reading), medium (today's readings), and Lock Screen accessories, each with interactive **Mark read** and the hide-passage option honored. *(Rewritten by D39; the large widget is P28.6.)*
- [ ] **P12.4** App Intents and App Shortcuts: "What's my reading today?", "Mark today's reading read", and "Open my plan", working with Siri, Spotlight, and the Action button.
- [ ] **P12.6** iPad: a sidebar layout and readable widths. Check that it runs on a Mac with Apple silicon as an iPad app. *(Rewritten by D39: comparison is P9.6.)*

## Phase 13: Paper and calendars

- [ ] **P13.1** The weekly printable checklist: a clean page through the web's print stylesheet and an iOS PDF through the share sheet, with checkboxes, references, the plan label, and the source note. Large print is an option. *(Rewritten by D39: per-use rights rules are P4.5.)*
- [ ] **P13.4** Calendar export: an `.ics` file of upcoming readings (all-day or at the reminder time). *(Rewritten by D39; the subscription URL is P28.7.)*
- [ ] **P13.5** Print and export tests: page breaks and large print.

## Phase 14: Accounts, backup, and sync

Moved to after 1.0 by D39 (2026-11-01); its items are in
[docs/roadmap.md](docs/roadmap.md). At 1.0 the app keeps everything on the
device (included in the device's own backups), the web keeps progress in
the browser, and both offer export and deletion (P8.10, P8.13).

## Phase 15: The web app: install and offline

- [ ] **P15.1** An installable web app: the manifest (name, icons from the owner's files, colors from the tokens), checked through Add to Home Screen on iPhone and installation on Android.
- [ ] **P15.2** Offline, finished: a service worker keeps the assets and the active plans' coming weeks, queues marks, and never caches another reader's data.
- [ ] **P15.4** Keyboard use throughout, and sharing through the Web Share API with a copy-link fallback. *(Rewritten by D39.)*
- [ ] **P15.5** Write `docs/browsers.md`: the support matrix (D30) and what was tested in each browser.
- [ ] **P15.6** Browser tests for every web flow at phone and desktop widths in Safari and Chrome, with Firefox and Edge checked by hand at each release.

## Phase 16: Public pages, legal, and App Store readiness

- [ ] **P16.1** The home page: what Day by Word is ("Find your plan. Read your Bible. Keep your place."), the plans actually in the catalog (never promised ones), the independence statement, and the way into Today.
- [ ] **P16.2** The support page (`/support`): support@daybyword.com, how to report a reading error (plan, assignment, and what is wrong), what is collected, and frequently asked questions.
- [ ] **P16.3 [OWNER]** The privacy policy and terms, drafted in `docs/legal/` from the real data flows: at 1.0, reading data stays on the device and in the browser, the server keeps none, and there are no analytics (D10, D39). The owner approves them before they are published. *(Rewritten by D39.)*
- [ ] **P16.4** The cookie statement, inside the privacy page: every cookie and browser storage key, what it holds, and why it is strictly necessary. *(Rewritten by D39.)*
- [ ] **P16.5** Sources, permissions, and criteria pages, generated from the catalog and `catalog/SOURCES.md`, with every required credit line.
- [ ] **P16.6** The accessibility statement: WCAG 2.2 AA, what was tested, known gaps, and how to report a barrier.
- [ ] **P16.7** The App Store package in `docs/app-store/`: the privacy manifest with accurate required-reason declarations; the privacy label (target "Data Not Collected" without an account, and accurate once accounts exist); age rating; export compliance; name, subtitle, description with the independence statement, and keywords; support and privacy URLs; review notes; and screenshots automated by UI tests in light and dark.
- [ ] **P16.8** Favicons and icons from the owner's files (D19); custom 404 and 500 pages; and a sitemap.
- [ ] **P16.9** A link check in `make check`: every internal link resolves, pages validate as HTML, and nothing loads from another host.

## Phase 17: Quality hardening

- [ ] **P17.1** VoiceOver on every screen (labels, traits, reading order, references read naturally) and screen readers on the web (VoiceOver, and NVDA where available).
- [ ] **P17.2** Dynamic Type at AX5 on every screen; Bold Text, Reduce Motion, Reduce Transparency, and Increase Contrast; contrast in both appearances.
- [ ] **P17.3** The web at 200% text and 400% zoom (320 CSS pixels) without loss; forced colors; keyboard alone with visible focus and a skip link.
- [ ] **P17.4** Time: daylight saving changes, travel across zones and the date line, midnight, leap days, and a device clock set wrong, all tested end to end for Today and reminders.
- [ ] **P17.5** An airplane-mode test of every offline feature, in the app and on the web.
- [ ] **P17.7** Security: a strict CSP with no `unsafe-*`, rate limits on every form and API call, request-size limits, secure cookies, dependency updates reviewed for advisories, no secrets in the app binary, Keychain for tokens, and suitable file-protection classes.
- [ ] **P17.9** Reminders, field-tested: a week of real reminders on a device across settings, with misses investigated.
- [ ] **P17.10** UI and browser tests for every critical flow in M2 and M3.
- [ ] **P17.11** A full review of every reader-facing string against AGENTS.md §3 (tone, neutrality, no guilt, no spiritual claims about records).

## Phase 18: Version 1.0 launch

- [ ] **P18.1** The rights audit: generate `docs/rights-audit.md` from `catalog/SOURCES.md`, with every served plan `cleared` for the territories it reaches (D16).
- [ ] **P18.2** Editorial sign-off: every [REVIEW] item at its level. *(Rewritten by D39: the prayer-book plans and their expert reviews come after 1.0.)*
- [ ] **P18.3 [OWNER]** The beta (D36): a few weeks on external TestFlight (with Apple's beta review) and on the web, with readers the owner invites. Agents triage feedback into items and fix what it finds; feedback is anonymized before it enters the repository.
- [ ] **P18.4** Submit version 1.0 for App Review in the US storefront (D16), confirming with the owner first where the host requires it.
- [ ] **P18.5** Open daybyword.com to search engines (remove P7.7's notice, `noindex`, and the `robots.txt` block) and submit the sitemap, on release day.
- [ ] **P18.6 [OWNER]** Announce Day by Word where the owner chooses.
- [ ] **P18.7** Tag `v1.0.0` and record what shipped in the Handoff notes.
- [ ] **P18.8** Add other storefronts as each one's rights review completes (D16).
- [ ] **P18.9** The after-launch learning loop (D12, D25) in `docs/learning.md`: the support inbox routine, an opt-in survey linked from Settings, the aggregate data Apple provides, and a quarterly note on what readers are saying, folded into this plan as items.

## After 1.0

Phases 6 and 14, the work D39 moved out of the 1.0 path (Phase 28), and
Phases 19–27 are in [docs/roadmap.md](docs/roadmap.md). Sessions read it
only when Phase 18 is finished or an item points there.

---

## Handoff notes

*Replaced each session; keep under 25 lines. History lives in Git.*

- **2026-11-01:** P3.1a and P3.2a done (E27, E28), then the owner approved
  D39, a leaner path to 1.0: BUILD.md was cut to the 1.0 work (103 open
  items, down from 148), later work moved to `docs/roadmap.md`, the
  findings and feature map to `docs/research/`, and the process lightened
  (AGENTS.md §7–§8, E29: `make check` per commit, `make check-full` at
  milestones). P3.1 and P3.2 are ticked under their rewritten scope.
- **Next: P3.3**, then P3.4 (the strict plan-file reference format and the
  formatter), P3.5–P3.7, and P3.9. Phase 4 follows with the plan format and
  compiler; the three first-light plans are P8.1.
- **Research downloads** (gitignored, re-fetchable; URLs and checksums in
  `catalog/SOURCES.md`): `research/ebible/` (KJV and WEB, which P3.6 can
  count words from), `research/stepbible/tvtms.txt`, and others.
- **Surprises:** Douay "1 Kings" is common "1 Samuel", so any reader of
  other sources' book names must use one convention at a time (E27). Bare
  `/regex/` literals do not compile in `swift` scripts; use `#/…/#`.
  Firefox windows are at least 500 px wide (phone widths are a manual
  check), synthetic simulator taps do not open SwiftUI menu pickers, and
  Tailscale SSH to `ubuntu-vm` needed re-authentication (Phase 7).
- **Optional for the owner:** allow remote automation in Safari's Developer
  settings for `DBW_WEBDRIVER=safari make tour-web`.
- **Owner to confirm when convenient:** D34's note about adding
  daybyword.com's entry to `ubuntu-vm-backup`. Design canvas:
  https://claude.ai/artifact/4YtusMm1DX7achVUPS67Lf (private).
