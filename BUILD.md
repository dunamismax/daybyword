# BUILD.md: The Build Plan

This is the master plan for **Day by Word**, a Bible reading companion: a
native iPhone and iPad app built in SwiftUI, and a SvelteKit web version at
[daybyword.com](https://daybyword.com) with PostgreSQL 18/Drizzle on the
owner's own machine behind Caddy. **D42 is the stack.** SvelteKit in `web/`
serves every page at daybyword.com and is the only server. AI agent
sessions build Day by Word step by step, working under
[AGENTS.md](AGENTS.md).

> **Day by Word.** Your Bible reading companion.
> *Find your plan. Read your Bible. Keep your place.*

## Now

*Replaced whenever an item is ticked or the state changes; read it first.*

| | |
|---|---|
| **Phase** | Phase 8, first light (M2): 12 of 14 (P8.5 waits on its device test, P8.14 on a TestFlight build). Phase 9 is finished (in BUILD-HISTORY.md). Phase 10, the launch catalog: 8 of 9, all eight plans in the catalog, P10.13 (the catalog review) open. Phase 11: 4 of 5 |
| **Next item** | **P11.5** (history: every reading's state and every change, and an archive of finished and paused plans); **P10.13** (the catalog review and criteria page); **P8.14** once the owner's steps below are done |
| **Also open** | **P7.3**: tick it once ubuntu-vm-backup's first daily snapshot with the `daybyword` database is verified (2026-11-22 07:30 UTC). **P12.1** waits on the Xcode sign-in below |
| **Waiting on the owner** | **Sign in to Xcode** (Xcode → Settings → Accounts) with the Apple ID of team D9QMP3LP8H: `make archive` stopped on 2026-11-22 with "No Accounts", so automatic signing cannot register the App Group `group.com.daybyword.app` that the app and its widget share (P12.1); after that, `make archive && make testflight` make the next TestFlight build, and P8.14 can be ticked. **P8.5's device test**: on an iPhone with YouVersion installed, choose a translation in Settings, then tap Open in YouVersion on a whole chapter, a verse range and a reading across chapters, and say what each did (docs/destinations.md, "What was tested"). Build 96 (2026-11-21) is the latest upload |
| **Live** | https://daybyword.com, in development (noindex, robots blocked): eight plans with their pages, the plan questions and grouped list, starting a plan, Today, Progress (with books explored), Settings and offline, with the reader's record in their own browser. Deployed 2026-11-22 at ce22517 after `make check-full` passed; candidate, live port and https://daybyword.com passed check-live (which now posts the plan questions), and the other sites answered as before |
| **Last updated** | 2026-11-22 |

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

1. Read AGENTS.md first. Then read **Now**, and this whole file once per
   session. It holds only the plan to version 1.0 (D39); the research findings are in
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
   `make check`, update **Now** and the **Build status** table, push, and
   replace the **Handoff notes** at the bottom. Run `make check-full` at
   each milestone and before every TestFlight build or deploy.
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
| M | SvelteKit/PostgreSQL alignment | M0 Stack alignment | 10 | 10 |
| 0 | Owner foundations | — | 6 | 6 |
| 1 | Repository and toolchain | M1 Foundation | 13 | 13 |
| 2 | Product, design system, and shells | M1 Foundation | 12 | 12 |
| 3 | Scripture references | M1 Foundation | 8 | 8 |
| 4 | The catalog | M1 Foundation | 8 | 8 |
| 5 | The reading engine | M1 Foundation | 11 | 11 |
| 6 | Church calendars and lectionaries | after 1.0 (roadmap) | — | — |
| 7 | Hosting at daybyword.com | M1 Foundation | 6 | 5 |
| 8 | First light | M2 First light | 14 | 12 |
| 9 | Choosing a plan | M3 Version 1.0 | 5 | 5 |
| 10 | The launch catalog | M3 Version 1.0 | 9 | 8 |
| 11 | Progress and history | M3 Version 1.0 | 5 | 4 |
| 12 | Widgets and Apple integration | M3 Version 1.0 | 4 | 0 |
| 13 | Paper and calendars | M3 Version 1.0 | 3 | 0 |
| 14 | Accounts, backup, and sync | after 1.0 (roadmap) | — | — |
| 15 | The web app: install and offline | M3 Version 1.0 | 5 | 0 |
| 16 | Public pages, legal, and App Store readiness | M3 Version 1.0 | 9 | 0 |
| 17 | Quality hardening | M3 Version 1.0 | 9 | 0 |
| 18 | Version 1.0 launch | M3 Version 1.0 | 9 | 0 |
| 19–28 | After 1.0 | roadmap | — | — |

**Now**, at the top of this file, holds the current state and the next item.

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

The owner answered D1–D38 on 2026-10-30 in an interactive session; later
rows carry their own dates. Under D3, agents may later record new
decisions, or revise an answered one only with strong evidence, as `(agent, date)` with their reasons. They never
reverse an owner's answer on product direction without asking.
Engineering consequences go in `docs/decisions.md`.

| ID | Question | Decision |
|---|---|---|
| D1 | Name and identifiers | **Day by Word** at daybyword.com, tagline "Your Bible reading companion", line "Find your plan. Read your Bible. Keep your place." Bundle ID **`com.daybyword.app`**, with extensions under it (for example `com.daybyword.app.widgets`) and the App Group `group.com.daybyword.app`. Xcode project and scheme `DayByWord`; URL scheme `daybyword://`; legacy server product `DayByWordServer` (owner, 2026-10-30; replaced by SvelteKit under D42). |
| D2 | The name, given daybyword.org (Research finding 2) | **Keep Day by Word, with no trademark search or legal review**; the owner accepts the risk (owner, 2026-10-30). Agents never contact daybyword.org's operators, and any claim that arrives goes to the owner. |
| D3 | Who builds and decides | **Agents, autonomously** (owner, 2026-10-30), as Beautiful Corner's D21: agents build everything, decide every open question (recorded as `(agent, date)` with reasons), and do every item, including server work (D34), deploys, TestFlight, and App Store Connect. The only limits are the host's safety rules (the owner's credentials, payments, and messages sent in the owner's name still need the owner) and honesty. Agents may install the developer tools the work needs on the owner's Mac (Homebrew formulae and casks, Swift toolchains through swiftly, user-local tools), but never use `sudo` or change system settings. |
| D4 | Repository visibility and license | **Public, all rights reserved** (owner, 2026-10-30): a `LICENSE` file says so (P1.2), and plans, data, and fonts keep their own rights. Every push publishes, so beta feedback stays anonymized and letter drafts stay generic. |
| D5 | Platforms and stack | Original SwiftUI/Hummingbird/SQLite choice (owner, 2026-10-30), now superseded in its web/server details by **D42** (which replaced D41). Keep the existing Swift Apple app; migrate web to SvelteKit and server data to PostgreSQL 18/Drizzle. |
| D6 | Android | Installable web app for now (owner, 2026-10-30). Native Android remains after 1.0 and requires a new platform decision; D41 does not authorize Expo, Kotlin or a new native target. |
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
| D27 | Hosting | **D41, as D42 revised it:** self-host the SvelteKit adapter-node server with PostgreSQL 18 behind the existing Ubuntu Caddy (owner-managed DNS-only Cloudflare records; Caddy's own certificates), using Docker Compose; private project DB and nightly encrypted off-server pg_dump/restore checks. Supersedes the Swift server/no-Docker/server-SQLite choice. D34 isolation rules remain. *Owner, 2026-11-21: the host's web platform contract replaces Compose here: a native systemd service on the host's Node and PostgreSQL 18 cluster, fix-forward deploys (E46).* |
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
| D40 | Previous unified stack | Next.js/PostgreSQL/Expo migration plan (owner, 2026-11-02); **withdrawn and superseded by D41 before implementation**. Its PM.1–PM.11 items are retired, never reused; Git retains their text. |
| D41 | Final stack, with only needed languages | *Web details superseded by D42 (owner, 2026-11-20); the rest stands.* **Owner, 2026-11-02:** Astro web, PostgreSQL with Drizzle (not server SQLite); React islands/Tailwind/shadcn only where useful. Swift and Python exist only where the project needs or requests them. The existing iPhone/iPad app justifies retaining SwiftUI; no Expo/Tauri or new native targets. Python is optional tooling, using uv/ruff if introduced, not a required rewrite. Astro APIs are the network boundary; clients never connect to Postgres. Better Auth remains deferred to Phase 14; no AI SDK/features under D23. Preserve Morning, offline/no-account privacy, app identity, catalog rights and 1.0 scope. Phase M aligns the foundation first; this session only updates docs. E33 records engine and data boundaries. |
| D42 | The stack | **SvelteKit 3 · Svelte 5 · TypeScript · Tailwind CSS 4 · PostgreSQL 18 + Drizzle ORM · Node (adapter-node) · Caddy** (owner, 2026-11-20). Replaces D41's Astro web choice and its optional React islands and shadcn: pages, form actions and `/api/v1` endpoints are SvelteKit routes, interaction is Svelte 5 components, styling is Tailwind CSS 4 with Morning's tokens, and the server is adapter-node's standalone Node build behind the existing host Caddy. PostgreSQL moves from 17 to 18. Everything else in D41 stands: the native SwiftUI app and its packages, the Swift catalog compiler as the rights gate, one engine specification with Swift and TypeScript runtimes held to the same fixtures (E33), no server SQLite, no AI, offline/no-account privacy, Morning, the app's identity, and the 1.0 scope. Better Auth (Phase 14) runs inside SvelteKit. E36 records the engineering. |

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
4. **One engine specification and shared cases**: keep Swift ReadingEngine
   for Apple clients; SvelteKit uses a TypeScript domain module checked
   against the same fixtures. E33 records the deliberate cross-language boundary;
   never copy rules into views, endpoints or SQL.
5. **Calendars computed once, at compile time**, when church calendars
   arrive after 1.0 (E5).
6. **A compiled, versioned catalog** that refuses unverified references,
   false claims, and uncleared sources (E6).
7. **Civil dates, not instants**; "today" is resolved once, at the edge
   (E7).
8. **Local-first**: the app works offline without an account, and at 1.0
   the web keeps progress in the browser (E8, D39).
9. **PostgreSQL 18/Drizzle on the server**; local Apple SQLite remains
   justified for offline reading. Clients reach the server only by HTTPS.
10. **Dependencies only when needed**: SvelteKit/Svelte/Tailwind/Drizzle
    on Node; native Swift retained; Python tooling optional (E33, E36).
11. **Modern browsers, server-rendered pages, a strict CSP** (E11, E19).
12. **Shared design tokens** for the app and the web (E12, E23).
13. **Our own simple formats**: `key: value` front matter, tab-separated
    schedules, JSON registries (E13).
14. **A date override for tests**: `-today YYYY-MM-DD` and `?today=` (E14).
15. **Internationalized from the start** (E15, E25).

### Milestones

- **M0 Stack alignment** (Phase M, finished 2026-11-20): the web on
  SvelteKit/PostgreSQL, the Swift server retired, and the native app kept.
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

## Phase M: Align with the final stack

Finished; its items and notes are in [BUILD-HISTORY.md](BUILD-HISTORY.md).

## Phase 0: Owner foundations

Finished; its items and notes are in [BUILD-HISTORY.md](BUILD-HISTORY.md).

## Phase 1: Repository and toolchain

Finished; its items and notes are in [BUILD-HISTORY.md](BUILD-HISTORY.md).

## Phase 2: Product, design system, and shells

Finished; its items and notes are in [BUILD-HISTORY.md](BUILD-HISTORY.md).

## Phase 3: Scripture references

Finished; its items and notes are in [BUILD-HISTORY.md](BUILD-HISTORY.md).

## Phase 4: The catalog

Finished; its items and notes are in [BUILD-HISTORY.md](BUILD-HISTORY.md).

## Phase 5: The reading engine

Finished; its items and notes are in [BUILD-HISTORY.md](BUILD-HISTORY.md).

## Phase 6: Church calendars and lectionaries

Moved to after 1.0 by D39 (2026-11-01); its items are in
[docs/roadmap.md](docs/roadmap.md).

## Phase 7: Hosting at daybyword.com

The site goes live early, marked as in development (D35). Phase M
prepares the SvelteKit/PostgreSQL image and scripts; this phase verifies the
actual host and provisions under D34. No reader records are stored at 1.0,
but nightly PostgreSQL backups begin with the first database deployment.

- [x] **P7.1** Finalize docs/deploy.md against the real host: release/shared env paths, shared lock, free loopback port (4316 planned), Compose volume/DB/roles, Caddy site convention and certificates (Caddy's own; DNS-only Cloudflare records are owner-managed). No Swift HTTP service or server SQLite.
  - *Result (agent, 2026-11-20):* docs/deploy.md, "The live host": paths, `with-deploy-lock` on /run/astro-deploy/lock, ports 4318/4319 (4316/4317 were taken), Compose volume/roles, `/etc/caddy/sites/*.caddy`, Caddy's own certificates.
- [x] **P7.2** Qualify make deploy from clean origin/main: SvelteKit adapter-node production image, release catalog export/import, one-shot Drizzle migrations, candidate boot on a spare port, /up and activation, with compatible image/config rollback and persistent DB volume.
  - *Result (agent, 2026-11-20):* `make deploy` (deploy/bin/release.sh) from a clean checkout equal to origin/main: export, `git archive` to `releases/<commit>`, `deploy.sh` inside `with-deploy-lock` (image, migrate/import, candidate on 4319, activate, rollback on failure), then public check-live.
- [ ] **P7.3** Provision only this project's database, roles, env files, units and Caddy site under the host's web platform contract (`bin/provision-app-database daybyword --web-access read-only`); record other-site responses before/after; validate and reload Caddy only through `caddy-apply`. Systemd timers for the nightly pg_dump and an isolated restore drill on the host cluster; the encrypted off-server copy is ubuntu-vm-backup's daily dump of the cluster. *(Rewritten 2026-11-21 for the contract, E46.)*
  - *Note (agent, 2026-11-21):* Moved to the contract (E46): `bin/provision-app-database daybyword --web-access read-only`; the container's final dump restored with equal row counts in every table (456 assignments, 3 plans, 2 imports); migration 0002 moved the catalog to schema app; the candidate passed on 4400; the Compose project, its volume and images were removed after the live site was verified. Both timers now work on the host cluster and each ran once (backup 64116 bytes, restore check passed). ubuntu-vm-backup's entry is a plain site with database `daybyword`; its verification rehearsal passed.
  - *Note (agent, 2026-11-20):* Done: the project's Compose/Postgres/env/Caddy resources, /etc/caddy archived, other sites compared, nightly pg_dump and monthly restore-check timers installed, first backup and restore check passed on the host. Open: the encrypted off-server copy; no `ubuntu-vm-backup` checkout or tool exists on the host or the Mac, so the owner's arrangement is needed.
  - *Note (agent, 2026-11-21):* each deploy had been recreating the database container (a few seconds without it, no data lost), because its two mounted files came from the release directory. They now come from `shared/postgres` (E43), and `make rehearse-deploy` deploys its second release from another directory and fails if the database container changes. On the host, cd13494 recreated the database one last time (its mounts moved), and the next deploy, 1cc5f7e, left `daybyword-postgres-1` with the same id (618753ad60f5) and start time (2026-11-21T05:23:29Z); 22 other site names answered the same before and after both.
- [x] **P7.4** First deploy after DNS verification and make check-full: apex HTTPS, www redirect retaining path, correct headers/CSP, valid origin TLS and healthy catalog/DB. Compare other sites and record commit/image/schema.
  - *Result (agent, 2026-11-20):* live 2026-11-20 at commit 7be7f76 (image `daybyword-web:<commit>`, schema 2 migrations, catalog ac986b77…, 0 plans): apex HTTPS, www 301 keeping path and query, HSTS, strict CSP and headers, healthy `/up` with a current catalog; all 20 other site names unchanged. `make check-full`'s parts all passed today (check, test-domain-browser, both tours, test-linux), not as one run.
- [x] **P7.6** make check-live verifies routes, redirects, TLS, headers, assets/hydration, no third-party loads, necessary cookies only and readiness. Deploy runs it; rehearse rollback without dropping the database.
  - *Result (agent, 2026-11-20):* check-live.sh exists and deploy runs it on the candidate and live port, and release.sh on https://daybyword.com (TLS, www redirect, HSTS, headers, robots, noindex, no cookies or third-party loads). Rollback rehearsed on the host the same day: 38972f5 → 7be7f76 with the database unchanged (1 catalog import before and after), checked, then 38972f5 redeployed with `make deploy`.
- [x] **P7.7** Keep the in-development line, noindex and robots crawl block until launch (P18.5).
  - *Result (agent, 2026-11-20):* the footer's in-development line, `noindex` on every page and `robots.txt` `Disallow: /` are live and checked by check-live; they stay until P18.5.

## Phase 8: First light

The first usable release: three original plans that exercise the three
behaviors (D39), in the app and on the web. Discover, preview, start, read
elsewhere, mark progress, receive a reminder, and return after a missed
day. Reliable reminders and quick logging matter more than a long feature
list.

- [x] **P8.1 [REVIEW]** The first three plans compiled and reviewed, each Day by Word's own: **Gospels at your pace** (sequential, P10.1), **the Bible in a year** (canonical order, balanced by reading time; pace or finish date, P10.2), and **Proverbs through the month** (follow the calendar by day of the month, P10.7). Each has its full plan-page metadata. *(Rewritten by D39: the 1979 Daily Office moved to the roadmap.)*
  - *Result (agent, 2026-11-21):* `catalog/plans/gospels-at-your-pace.plan` (60 readings), `bible-in-a-year.plan` (365) and `proverbs-through-the-month.plan` (31), each at `reviewed`. Their schedules are computed by `scripts/plans.swift` under the rules in docs/plans.md, and `make check` fails if a schedule is not what its rule gives. Reviewed under docs/editorial.md: the rules (whole chapters, canonical order, each chapter once), the compiler's facts against each page's wording (31,102, 3,779 and 915 verses, no repeats or omissions; lightest and heaviest readings), the wording against AGENTS.md §3, and rights (`daybyword-original`, cleared). Both catalog builds hold all three. *Not yet:* a page that shows them (P8.2, P8.10).
- [x] **P8.2** Starting a plan: a plain plan page with a sample week and workload; a start date, or "join today's reading" for calendar plans; the behavior, explained; reading days; how the reader reads (a physical Bible, YouVersion, or another app, with Copy reference); and a reminder offer. Notification permission is requested only after the reader chooses a reminder.
  - *Note (agent, 2026-11-21):* split in two. P8.2a is the engine's part; P8.2b is the flow itself, on the web and in the app.
  - [x] **P8.2a** The days ahead, in both runtimes: for an enrollment and a date, each coming date with the readings expected on it, which gives the sample week (a candidate `enrolled` event), the coming week, and the checklist (P8.10, P13.1).
    - *Result (agent, 2026-11-21):* `Enrollment.comingDays(from:count:)` (`Ahead.swift`) and `comingDays` (`ahead.ts`), specified in docs/engine.md's "The days ahead". `ahead.json` (29 cases, checked by hand) passes in Swift and Node, and a Swift test marks each listed day's readings read and finds Today showing the next day's list.
  - [x] **P8.2b** In the app: the plan list and the plan page with its sample week and workload, and the start flow: start date or "join today's reading", the behavior explained, reading days, how the reader reads, and the reminder offer. *(Rewritten 2026-11-21: the web's plan pages are P8.10a and its start flow is P8.10c.)*
    - *Result (agent, 2026-11-21):* `Catalog` now reads each plan's facts and readings' words; `JournalStore` keeps the journal on the device and `Library` folds it (E47). Plans lists the catalog (and "My plans"); `PlanView` shows what the web's page shows, from `PlanPresentation`, with a link to the plan's week; `StartPlanView` records one `enrolled` event, previews a finish date's load from the engine (and offers the later date that fits the limit), and asks for notification permission only when a reminder is turned on. Seen in the iOS Simulator (iPhone 18 Pro), starting Gospels at your pace with both behaviors previewed. *Not here:* scheduling the reminder itself (P8.8).
- [x] **P8.3** Today: each active plan's next reading, with its label ("Gospels at your pace — Reading 12"), large references, **Open in …**, **Copy reference**, and **Mark read**. Rest days and finished days say so plainly, with no fanfare and no nagging.
  - *Result (agent, 2026-11-21):* in the app (`TodayView`): one card a plan with its label, the reference at desk-glance size, Open in YouVersion (P8.5) for a reader who reads there, Copy reference and Mark read, every status in the engine's words, and the short-month note. Seen in the iOS Simulator in light and dark. The web's Today is P8.10c.
- [x] **P8.4** Marking: complete with one deliberate tap; mark part read ("part of it"); skip (labeled as a scheduling decision); log late for an earlier date; undo and redo. All of these are journal events.
  - *Result (agent, 2026-11-21):* in the app: Mark read, and under More, Mark part read, Skip (confirmed with "It won't count as read") and Log an earlier day (a date from the start to today; a calendar plan logs that date's own reading); a banner offers Undo, then Redo, each an `undone` event. Tested in `LibraryTests` and seen in the Simulator with the date pinned (`-today`). Which verses of a partial reading is not asked yet (P11.4 reads them). The web's marking is P8.10c.
- [ ] **P8.5** Opening a reading (D26): an adapter for YouVersion and Bible.com that builds the best link it can (the passage, or the chapter where that is the limit, said plainly) in the reader's chosen translation, opening the app where it is installed, and Copy reference everywhere. Test it on a device and record the date, app version, link format, and limits in `docs/destinations.md`.
  - *Note (agent, 2026-11-21):* built: `BibleLink` (ReadingEngine) and `bibleLink` (web domain), pinned by `bible-links.json` in both runtimes; a Bible.com universal link, which Apple's association file gives to the YouVersion app (E49). The reader picks one of 22 translations checked on Bible.com (no default); a reading across chapters opens at its first chapter, and Today says so. In the app: Open in YouVersion on Today, the translation under "How you read" in Settings and the start flow. Seen in the Simulator opening Bible.com's Matthew 1 (KJV) in Safari. **Not ticked:** the device test with YouVersion installed (docs/destinations.md, "What was tested") waits on the owner; the web's button comes with P8.10c.
- [x] **P8.6** Physical Bible mode: references at the desk-glance size, a keep-the-screen-awake option, book and chapter called out for finding the place in print, and no link.
  - *Result (agent, 2026-11-21):* in the app: "How you read" (chosen when starting a plan, and in Settings) set to a physical Bible adds `PlaceInPrint`'s line under each reference ("Mark · chapter 4 · verses 1–20") and offers "Keep the screen awake on Today" in Settings; no link is shown (P8.5 adds links for the other ways). Seen in the Simulator in light and dark. The web's is with P8.10c.
- [x] **P8.7** The return flow over P5.8: a short welcome, the choices that apply with their previews, and a confirmation. History is never altered.
  - *Result (agent, 2026-11-21):* in the app, `WelcomeBack` heads a plan's card on Today after a gap: "Welcome back. Here's where you left off.", each choice the engine offers with its effect worked out by folding the journal with the answer added (`Journal.previewing`), a confirmation sheet, and the `returned` event with Undo. Tested in `LibraryTests` and seen in the Simulator. The web's is with P8.10c.
- [x] **P8.8** iOS reminders over P5.12: local notifications in a rolling window; actions **Mark read**, **Snooze**, and **Open**, grouped by plan; an option to hide passage details on the Lock Screen; quiet hours; a maximum per day; pending requests removed when the day's reading is marked; rescheduling on time-zone change. Turning reminders off never limits the app.
  - *Result (agent, 2026-11-21):* `ReminderScheduler` asks the engine for 60 reminders and replaces the pending ones after every journal write, setting change, activation, and time-zone or clock change (E50); requests are threaded by enrollment. Settings has each plan's reminder (a `changed` event from today), "Name the reading in reminders", quiet hours and reminders a day. Five tests in `RemindersTests`. Seen in the iOS Simulator: permission asked only on turning a reminder on; a real reminder arrived at its minute ("Proverbs through the month: Proverbs 21."); its Mark read recorded the reading; tapping a reminder opened Today from Plans. *Not exercised end to end:* Snooze and a time-zone change on a device (unit-tested; P17.4, P17.9 field-test them).
- [x] **P8.9** A small and a Lock Screen widget showing the next reading, with an interactive **Mark read** (an App Intent writing to the shared journal through the App Group) and an obvious way to undo in the app.
  - *Result (agent, 2026-11-21):* the journal moved to the App Group container (an earlier one is moved there once, E51); `MarkReadIntent` records the reading the widget shows, only while unread; the small widget and the Lock Screen's rectangular one show the first plan with a reading today, or its day in Today's words, and open Today when tapped. Today offers Undo for the last mark made today (the widget's, a reminder's). Seen in the iOS Simulator: the journal moved, the widget's Mark read recorded the reading and the widget redrew, Undo in the app brought it back, and the Lock Screen widget showed the real state. *Before a device build:* register the App Group through automatic signing (P12.1).
- [x] **P8.10** The web: browse and preview plans; print a week's checklist; start a plan and use Today and marking, with progress kept in the reader's own browser and nothing stored on the server (D39). SvelteKit endpoints compute through the TypeScript domain module from request bodies, retain nothing and log no personal records; cached upcoming readings and IndexedDB marks support offline use. Swift uses the same contract fixtures (E33). A plain page says what is kept where and how to export or clear it. *(Rewritten by D39; server-side profiles are P28.8.)*
  - *Note (agent, 2026-11-21):* split in four, in the order they can be built. Ticked with P8.10d; its offline part (cached coming readings, marks queued offline) is P8.11's.
  - [x] **P8.10a** Browse and preview: Plans lists the catalog's plans, and each plan has its page (what it is, whom it suits, workload, a sample week, coverage, how it works, limitations, source and review), rendered on the server from PostgreSQL.
    - *Result (agent, 2026-11-21):* `web/src/lib/server/catalog/read.ts` reads the served import as the web role and `present.ts` makes the pages' content (the compiler's facts, the engine's sample week, the string table's words); `/plans` and `/plans/<id>` show them, and an id that is no plan in the catalog is not found. `scripts/with-catalog.sh` gives `make serve-web`, the production tests and the tour a throwaway PostgreSQL with the release catalog, so they use the code the live site does. Seen in a browser (desktop width in dark, phone width in light) with no console errors or CSP violations and no sideways scroll; the web tour visits two plan pages in light and dark at both widths. Choices in E45. tests/fixtures/routes.json is version 3. *Not here:* starting a plan (P8.2b, P8.10c), and the app's plan pages (P8.2b).
  - [x] **P8.10b** A week's printable checklist at `/plans/<id>/week?start=`, from the engine's days ahead (P8.2a), through the print stylesheet (with P13.1).
    - *Result (agent, 2026-11-21):* `planWeek` in `present.ts` lists the seven days from `start` for a reader who begins that day (each date's every reading, a box to tick, rest days named), or the sample week with no start; a plain GET form picks the date, `/assets/print.js` shows a Print button, and `@media print` (with light tokens on paper, `scripts/tokens.swift`) leaves the checklist alone. The plan page links to it. Seen in a browser at desktop and phone widths with no console errors, and printed to PDF in headless Firefox from a dark-theme browser. *Not here:* large print and the iOS PDF (P13.1).
  - [x] **P8.10c** Start a plan and use Today and marking in the browser: progress in IndexedDB, compute endpoints that keep nothing, and the page that says what is kept where. Needs E38's choice for client interaction under the strict CSP. *(Rewritten 2026-11-21: the cached coming readings are P8.11's offline work.)*
    - *Result (agent, 2026-11-21):* E52: `static/assets/reading.js` keeps the journal in IndexedDB and sends it to `POST /api/v1/today` (Today's cards, rendered by `TodayCards.svelte`) and `POST /api/v1/events` (an action's new events, made and checked by the domain module), which keep nothing and log route and status only; the production body limit is 1M. `/plans/<id>/start` starts a plan (start date or today's reading, behavior, finish and limit, reading days); Today has Mark read, Copy reference, Mark part read, Skip (confirmed) and Undo for the day's last mark; Settings' "Your data" says what is kept where, and exports and deletes. Six tests in `web/test/reading.test.ts`; routes.json is version 4. Seen in a browser against the production build: started Gospels at your pace, Today before and on the start date, Mark read and Undo, export's file and delete, at desktop width in dark and at phone width, with no console errors or CSP violations.
  - [x] **P8.10d** The web's counterparts of the app's first light: log an earlier day (P8.4), Open in YouVersion with the translation and how you read (P8.5, P8.6's paper lines), the welcome back after a gap (P8.7), Progress (P8.12), book names in Settings (P8.13), and the finish date's load previewed before starting (P8.2b). *(Added 2026-11-21 from P8.10c's split.)*
    - *Result (agent, 2026-11-21):* Settings' how you read, translation and book names (settings.json version 2, checked by both platforms); Today's place in print, Open in YouVersion with "Opens at …", or the way to choose a translation; Log an earlier day (a calendar plan's earlier day is that date's reading); Undo, then Redo, for the tab's last action (sessionStorage); the welcome back with each choice's effect and a confirmation (`return` action, only a choice offered today); Progress (`POST /api/v1/progress`: the week in words and symbols, readings by state, next reading, finish); and the finish date's preview (`POST /api/v1/preview`, with the later date that fits), a start beyond the limit being refused. Fourteen tests in `web/test/reading.test.ts`. Seen in a browser against the production build.
- [x] **P8.11** Offline: the app works fully in airplane mode. The web keeps Today and the coming week for the active plans (cached coming readings, from P8.10c), queues marks made offline with their event ids, and says clearly when it is offline. *(E52: event ids made offline need the domain module in the browser.)*
  - *Result (agent, 2026-11-21):* E53. The app makes no network request (audited: its only address is the Bible.com link handed to the system), so everything but opening a link works offline. The web: a service worker keeps each release's files and Today, Progress and Settings; `/api/v1/today` answers six more days, kept in `localStorage`; a mark made with no connection waits in IndexedDB with an id made then and its date, and is sent when Today next loads or the browser is online again (the server keeps the id and ignores a repeat; one test). Seen in a browser against the production build with the server stopped: Today opened from the service worker with "You're offline", a mark was kept, and on restart it was sent with its id and Today showed the day read. *Not done here:* a device in airplane mode, for the app and the web (P17.5).
- [x] **P8.12** Progress, first version: assignments completed, recent reading days, and the next reading; a quiet welcome after returning from a gap.
  - *Result (agent, 2026-11-21):* in the app: a seven-day strip (read, a reading day, a rest day, each a symbol and words), and for each plan its readings by state, the next reading and the projected finish, from the engine's progress rules. The welcome after a gap is on Today (P8.7), where docs/product.md puts it. Seen in the Simulator. The web's is with P8.10c.
- [x] **P8.13** Settings, first version: reminders, the way to read and translation, book-name convention (D29), appearance, export of all personal data (JSON), delete all data, about, and version.
  - *Result (agent, 2026-11-22):* in the app: how you read (and the screen kept awake for paper), the translation (P8.5), reminders (P8.8), book names (D29), appearance and reference size, Export (the journal as JSON, `Library.export`; tested), delete everything with a confirmation, about and version; the web's Settings is P8.10c and P8.10d (no reminders on the web at 1.0). SwiftUI's `ShareLink` closed the Settings sheet instead of sharing, so `ShareSheet` presents the system's share sheet through UIKit; `LaunchTests.testExportOpensTheShareSheet` sees it open over Settings with the file "Day by Word reading record" (JSON) in the iOS Simulator (iPhone Air). The Simulator tool's injected taps never reach Settings' rows; XCUITest's taps do.
- [ ] **P8.14** Ship first light: an internal TestFlight build, and daybyword.com deployed with the three plans. Run `make check-full` first. This opens [GATE DEMO].
  - *Note (agent, 2026-11-22):* daybyword.com serves ce22517 with all eight plans and first light's web (deployed after `make check-full`). Build 96 (8872016) is the latest TestFlight upload; the next build, with P8.3–P8.13 and Phase 9, stopped at `make archive` with "No Accounts": Xcode needs the owner's sign-in so automatic signing can register the App Group (P12.1). Not ticked: that build, and P8.5's device test.

## Phase 9: Choosing a plan

Finished; its items and notes are in [BUILD-HISTORY.md](BUILD-HISTORY.md).

## Phase 10: The launch catalog (parallel with Phases 9–17)

Each plan is Day by Word's own (D39), built from verse data and documented
rules, compiled, checked against its claims (P4.4), reviewed
(`docs/editorial.md`), and given complete plan-page metadata. M'Cheyne, the
prayer-book plans, and the deuterocanonical books follow after 1.0
(roadmap).

- [x] **P10.1 [REVIEW]** **Gospels at your pace** (from P8.1): the four Gospels, 89 chapters, in readings sized by reading time.
  - *Result (agent, 2026-11-21):* done with P8.1: 60 readings of one to three whole chapters, each Gospel on its own, about 3 to 10 minutes (docs/plans.md).
- [x] **P10.2 [REVIEW]** **The Bible in a year**, canonical order, balanced by reading time without splitting chapters unless the plan says so; permits pace and finish-date behaviors.
  - *Result (agent, 2026-11-21):* done with P8.1: 365 readings of whole chapters, the testaments balanced apart (280 and 85), about 6 to 15 minutes; `whole-bible` over the Protestant canon, which the compiler verifies.
- [x] **P10.3 [REVIEW]** **The Bible in a year, five days a week**, with rest days intentional.
  - *Result (agent, 2026-11-22):* `bible-in-a-year-five-days.plan`: the Bible in a year's rule in 260 readings (199 and 61 by the testaments' words), paced for five days with two rest days; about 12–16 minutes, 10 to 20. `whole-bible`, verified by the compiler; reviewed under docs/editorial.md (rules, facts against the wording, §3, rights).
- [x] **P10.4 [REVIEW]** **The New Testament in a year, five days a week**: its 260 chapters, one a day.
  - *Result (agent, 2026-11-22):* `new-testament-in-a-year-five-days.plan`: 260 readings of one chapter, five a week; about 3 minutes, 1 to 9. Every verse of the 27 books (7,957), verified; reviewed.
- [x] **P10.5 [REVIEW]** **The Story of Scripture**: a short introduction to the biblical narrative in about 50 readings. Its selection involves editorial judgment, which the plan page explains.
  - *Result (agent, 2026-11-22):* `story-of-scripture.plan`: 51 narrative passages from 20 books, in the order the story unfolds, from Genesis 1 to Revelation 21–22; about 4–5 minutes (2 to 13), five a week, about eleven weeks; `selection` coverage (2,150 verses, none repeated). The selection is listed in `scripts/plans.swift` with what each reading tells, and docs/plans.md says how it was chosen; its page says it is one selection among many and claims no passage matters more. Reviewed (rules, the compiler's facts against the wording, AGENTS.md §3, rights); in "A place to begin" with Gospels at your pace.
- [x] **P10.6 [REVIEW]** **A psalm a day**: 150 readings, with Psalm 119 in sections if workload calls for it, in English (Hebrew) numbering, which the plan page states. *(Rewritten by D39; other numberings are P3.8.)*
  - *Result (agent, 2026-11-22):* `psalm-a-day.plan`: each psalm a reading and Psalm 119 in 11 runs of two 8-verse stanzas (its words are ten times the middle psalm's), so 160 readings; about 1 minute, up to 5–6. Its limitations state the Hebrew numbering and the Greek and Latin one (Psalm 23 is their 22). Every verse of Psalms (2,461), verified; reviewed.
- [x] **P10.7 [REVIEW]** **Proverbs through the month**: 31 readings by day of the month, with the 31st handled honestly in shorter months.
  - *Result (agent, 2026-11-21):* done with P8.1: Proverbs *n* on day *n*; the plan's limitations say which months lack which chapters, and the engine lists them on a short month's last day (P5.7).
- [x] **P10.11 [REVIEW]** **Paul's letters**, in canonical order, with an optional arrangement in an order the plan page explains and labels as one view among several. *(Rewritten 2026-11-22: the optional arrangement is P28.9.)*
  - *Result (agent, 2026-11-22):* `pauls-letters.plan`: the thirteen letters that open with Paul's name, in printed order, one chapter a reading (87), five days a week; about 2–3 minutes. Hebrews, which names no author, is left out and the plan says so, taking no side on authorship or the order of writing. Every verse of the 13 letters (2,033), verified; reviewed.
- [ ] **P10.13** The catalog review: every launch plan at `reviewed`, every claim verified, every rights entry `cleared`, and the criteria page current. Plans that are not ready wait; the catalog launches with what is ready.

## Phase 11: Progress and history

- [x] **P11.1** The Progress screen: assignments completed, recent reading days (a plain week strip, never a heat map of performance), books explored, and the next reading.
  - *Result (agent, 2026-11-22):* first light's Progress (P8.12, P8.10d) had the week strip, each plan's readings by state and its next reading; both platforms now add "Books explored", the engine's coverage books in the Bible's order under the reader's book names, in a card of its own with "Reading in a book is not reading all of it", apart from each plan's record. Tested in `web/test/reading.test.ts`; seen in the iOS Simulator (Genesis, after marking the Story of Scripture's first reading) and in a browser.
- [x] **P11.2** Quiet celebrations of returning after a gap, finishing a book, finishing a plan, and keeping a rhythm the reader chose: words, not confetti, and never a comparison with anyone else.
  - *Result (agent, 2026-11-22):* the engine's rule (docs/engine.md, "Quiet celebrations"; E56): on a date, each plan's return after a gap, the books it finished (its own coverage) and its finishing, then the week's reading days each read, on the week's last; `celebrations.json` (41 cases, checked by hand) passes in Swift and Node. Today shows them in the plan's card on the accent tint, and the week's once after the cards, in the app and on the web; nothing stored, nothing in reminders. Seen in the iOS Simulator (the week kept, a return, "You've read all of Ruth.", light and dark) and in a browser against the production build (the week kept, a return). Two web tests in `reading.test.ts`.
- [x] **P11.3** The optional streak (D17): off by default, measured against the reader's reading days, small, and never mentioned in notifications.
  - *Result (agent, 2026-11-22):* the engine's streak (P5.11) behind a setting off by default, "Show reading days in a row on Progress" in the app and "Reading days in a row" on the web (settings.json version 3, checked by both); when on, Progress says "3 reading days in a row" in a caption under the week strip, only while there is one (never a zero), and reminders never mention it (P5.12). Seen in the iOS Simulator and in a browser against the production build; `LaunchTests.testTheStreakShowsOnlyWhenTurnedOn` turns it on and off in Settings, and a web test in `reading.test.ts`. The string table's voice test still refuses the word "streak", so readers never see it.
- [x] **P11.4** Coverage: unique verses read, by book, with partly read chapters shown as partial. Repeats never inflate it, and it is kept apart from plan completion.
  - *Result (agent, 2026-11-22):* the engine gives each book explored with its verses read of its verses and its chapters read whole and in part (`Coverage.byBook`, `coverageByBook`; docs/engine.md "Progress"), pinned by `progress.json` in both runtimes. Progress's "Books explored" card, apart from each plan's record, lists each book: "98 of 1,533 verses · 3 chapters read in full · 1 chapter in part", or "All 85 verses". Seen in the iOS Simulator and in a browser against the production build; a web test checks a partly read chapter, a second plan through the same book adding nothing, and a whole book.
- [ ] **P11.5** History: every assignment's state and every change, late logging, undo, and an archive of finished and paused plans.

## Phase 12: Widgets and Apple integration

- [ ] **P12.1** The App Group and the capabilities the extensions need, registered through Xcode's automatic signing on the owner's account (D33).
  - *Note (agent, 2026-11-22):* the app and widget carry `group.com.daybyword.app` (P8.9). `make archive` (with `-allowProvisioningUpdates`) failed: Xcode has no account signed in ("No Accounts"), so the wildcard profile lacks the App Groups capability. Waits on the owner's Xcode sign-in.
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
the browser, and both offer export and deletion (P8.10, P8.13). Better Auth inside
SvelteKit with Drizzle/PostgreSQL supplies optional accounts later (D42).

## Phase 15: The web app: install and offline

- [ ] **P15.1** An installable web app: the manifest (name, icons from the owner's files, colors from the tokens), checked through Add to Home Screen on iPhone and installation on Android.
- [ ] **P15.2** The web offline, finished: SvelteKit's service worker (`src/service-worker.ts`) keeps the assets and the active plans' coming weeks, queues marks, and never caches another reader's data.
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
- [ ] **P17.7** Security: server-only Drizzle/Postgres imports and private DB networking; SvelteKit form-action/API validation, origin checks and adapter-node `BODY_SIZE_LIMIT`; a strict CSP with no `unsafe-*`, rate limits on every form and API call, request-size limits, secure cookies, dependency updates reviewed for advisories, no secrets in the app binary, Keychain for tokens, and suitable file-protection classes.
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

- **2026-11-22 session:** P8.13 (Export's share sheet: SwiftUI's ShareLink
  closed Settings, so `ShareSheet` presents through UIKit); five more
  plans, P10.3–P10.6 and P10.11, so all eight 1.0 plans are in; Phase 9
  finished (the picker and recommendations, E54; goals; plan pages'
  length and permissions; descriptions, link previews and the sitemap,
  E55); P11.1 (books explored on Progress). Deployed twice.
- **Catalog schema 4, export format 2:** goals live in `catalog/goals.json`
  (not plan front matter: changing a published plan's content needs a new
  version). PostgreSQL keeps them per import in `catalog_goals` (0003).
- **Forms on the web** work only with `Referrer-Policy: same-origin` and
  `server.ts`'s `X-Forwarded-Proto` default (AGENTS.md §11, E54).
- **The Story of Scripture** is an editorial list in `scripts/plans.swift`;
  `generate` writes it and refuses a reading not in its shortest writing.
- **TestFlight is blocked** on the owner's Xcode sign-in (Now). Nothing
  else waits on it; the archive builds once signing is possible.
- **Testing:** the Simulator tool's taps never reach rows inside the
  Settings sheet; use an XCUITest there (`LaunchTests`). Booted simulators
  are often other sessions'; iPhone Air (CC73BF5B-…) was free.
- **Next:** P11.2 needs an engine rule (finishing a book or a plan, a
  rhythm kept): specification and shared cases first, then both runtimes.
  Stage by path (§8).
