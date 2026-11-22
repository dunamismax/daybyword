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
| **Phase** | M3 Version 1.0 under way: TestFlight build 131 uploaded (processing), and daybyword.com serving 2b906ec. Phases M, 0–11 and 13 are finished (in BUILD-HISTORY.md; 6 moved to the roadmap). Phase 12: 2 of 4 (P12.1, P12.4; P12.2a and P12.6a done). Phase 15: 3 of 5 (P15.2, P15.4, P15.5; P15.1a and P15.6a done). Phase 16: 6 of 9 (P16.1, P16.2, P16.5, P16.6, P16.8, P16.9; P16.3 and P16.4 drafted) |
| **Next item** | **Phase 16**: P16.7 (the App Store package); P16.3 and P16.4 wait on the owner's approval of the drafts. Then Phase 17 (quality hardening). Still open: **P12.2b** (Lock Screen widgets, on a device), **P12.6b** (the app on a Mac), **P15.1b** (installing on Android) and **P15.6b** (the tour in Safari), each waiting on the owner or a device |
| **Also open** | [GATE DEMO] is open since P8.14; nothing in this file waits on it (D38's letters come with their plans, after 1.0) |
| **Waiting on the owner** | **Build 131**: try Siri ("What's my reading today in Day by Word?"), the iPad sidebar, Share as PDF on a plan's week, and Add the next four weeks to a calendar. **P12.2b**: say whether the Lock Screen's three Day by Word widgets show and Mark read works there. **P12.6b**: install build 131 on the Mac with TestFlight for Mac and say whether it runs (or allow an agent to register this Mac in Xcode). **P15.1b**: install daybyword.com from Chrome on an Android phone, or allow an agent to download an Android emulator image. **P15.6b**: turn on Safari's "Allow remote automation" (Settings › Advanced › Show features for web developers, then Developer › Allow remote automation). **P16.3**: read and approve `docs/legal/privacy.md` and `docs/legal/terms.md`, answering the questions at the end of each |
| **Live** | https://daybyword.com, in development (noindex, robots blocked), serves 2b906ec (deployed 2026-11-22 after `make check-full`): everything before, plus large print on a plan's week, the calendar download on Progress, the installable web app (manifest and icons), and the offline page with Plans kept offline. Candidate, live port and https://daybyword.com passed check-live, and the other sites answered as before |
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
| 7 | Hosting at daybyword.com | M1 Foundation | 6 | 6 |
| 8 | First light | M2 First light | 14 | 14 |
| 9 | Choosing a plan | M3 Version 1.0 | 5 | 5 |
| 10 | The launch catalog | M3 Version 1.0 | 9 | 9 |
| 11 | Progress and history | M3 Version 1.0 | 5 | 5 |
| 12 | Widgets and Apple integration | M3 Version 1.0 | 4 | 2 |
| 13 | Paper and calendars | M3 Version 1.0 | 3 | 3 |
| 14 | Accounts, backup, and sync | after 1.0 (roadmap) | — | — |
| 15 | The web app: install and offline | M3 Version 1.0 | 5 | 3 |
| 16 | Public pages, legal, and App Store readiness | M3 Version 1.0 | 9 | 6 |
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

Finished; its items and notes are in [BUILD-HISTORY.md](BUILD-HISTORY.md).

## Phase 8: First light

Finished; its items and notes are in [BUILD-HISTORY.md](BUILD-HISTORY.md).

## Phase 9: Choosing a plan

Finished; its items and notes are in [BUILD-HISTORY.md](BUILD-HISTORY.md).

## Phase 10: The launch catalog

Finished; its items and notes are in [BUILD-HISTORY.md](BUILD-HISTORY.md).

## Phase 11: Progress and history

Finished; its items and notes are in [BUILD-HISTORY.md](BUILD-HISTORY.md).

## Phase 12: Widgets and Apple integration

- [x] **P12.1** The App Group and the capabilities the extensions need, registered through Xcode's automatic signing on the owner's account (D33).
  - *Result (agent, 2026-11-22):* with Xcode signed in again, `make check-signing` was ready and `make archive` (with `-allowProvisioningUpdates`) registered the App Group: in build 126's archive both `com.daybyword.app` and `com.daybyword.app.widgets` are signed for team D9QMP3LP8H with `group.com.daybyword.app`, and the App Store export and upload succeeded.
  - *Note (agent, 2026-11-22):* the app and widget carry `group.com.daybyword.app` (P8.9). `make archive` (with `-allowProvisioningUpdates`) failed: Xcode has no account signed in ("No Accounts"), so the wildcard profile lacks the App Groups capability. Waits on the owner's Xcode sign-in.
- [ ] **P12.2** Widgets: small (the next reading), medium (today's readings), and Lock Screen accessories, each with interactive **Mark read** and the hide-passage option honored. *(Rewritten by D39; the large widget is P28.6.)*
  - *Note (agent, 2026-11-22):* split in two: the Home Screen widgets were seen working in the iOS Simulator; the Lock Screen's new accessories were not, since its editor would not open there. Mark read stays only where the reading is named: an inline accessory cannot hold a button, and the circular one names no reading, so it opens Today.
  - [x] **P12.2a** The Home Screen: small (the next reading) and medium (today's reading in each plan, up to three, each with Mark read).
    - *Result (agent, 2026-11-22):* one provider gives today's readings across plans; the medium widget lists them with Mark read (`MarkReadIntent`). Seen in the iOS Simulator (iPhone 18 Pro): added from the widget gallery, it showed Psalm 1 and Proverbs 22; Mark read recorded each in the shared journal and the widget redrew (once only after the app opened: the Simulator held the first reload).
  - [ ] **P12.2b** The Lock Screen: the rectangular accessory (the next reading, Mark read), an inline line and a circular symbol that opens Today, and with "Name the reading in reminders and on the Lock Screen" off (mirrored into the App Group by `Library` and the setting), the plan and "Reading 12" instead of the passage. Built with P12.2a; *not seen yet*: the Simulator's Lock Screen editor did not open from Customize. See them on a Lock Screen (a device, or a Simulator whose editor opens) and tick.
- [x] **P12.4** App Intents and App Shortcuts: "What's my reading today?", "Mark today's reading read", and "Open my plan", working with Siri, Spotlight, and the Action button.
  - *Result (agent, 2026-11-22):* three intents in the app (`apple/App/Intents/`, E58) on the app's own library, with App Shortcut phrases (`AppShortcuts.xcstrings`). Mark read names the reading and asks first. Seen in the iPad simulator's Shortcuts app: all three listed; Mark read asked "Mark Matthew 1–3 read, in Gospels at your pace?" and recorded it (Today then offered Undo); Today's Reading answered "That's today's reading"; Open Plan brought the app forward on Today. Siri's voice and the Action button were not tried (the Simulator has neither); they run the same App Shortcuts.
- [ ] **P12.6** iPad: a sidebar layout and readable widths. Check that it runs on a Mac with Apple silicon as an iPad app. *(Rewritten by D39: comparison is P9.6.)*
  - *Note (agent, 2026-11-22):* split: the iPad work is done; running on a Mac waits for a device registration or a TestFlight build.
  - [x] **P12.6a** The sidebar (`.sidebarAdaptable`, the tab bar on iPhone) and every screen held to a readable 720-point column (`ReadableWidth`, and `readableRows()` for History's Form). Seen on the iPad Air 11-inch simulator in portrait and landscape, light and dark.
  - [ ] **P12.6b** Run it on a Mac with Apple silicon as an iPad app. Building for "My Mac (Designed for iPad)" stops at signing: this Mac is not a registered device on the owner's account. Either the owner allows registering it (Xcode does it with `-allowProvisioningDeviceRegistration`), or the owner installs the next TestFlight build on the Mac through TestFlight for Mac, which needs no registration. See it run and tick.

## Phase 13: Paper and calendars

Finished; its items and notes are in [BUILD-HISTORY.md](BUILD-HISTORY.md).

## Phase 14: Accounts, backup, and sync

Moved to after 1.0 by D39 (2026-11-01); its items are in
[docs/roadmap.md](docs/roadmap.md). At 1.0 the app keeps everything on the
device (included in the device's own backups), the web keeps progress in
the browser, and both offer export and deletion (P8.10, P8.13). Better Auth inside
SvelteKit with Drizzle/PostgreSQL supplies optional accounts later (D42).

## Phase 15: The web app: install and offline

- [ ] **P15.1** An installable web app: the manifest (name, icons from the owner's files, colors from the tokens), checked through Add to Home Screen on iPhone and installation on Android.
  - *Note (agent, 2026-11-22):* split: the manifest and the iPhone are done; no Android emulator image is installed on the owner's Mac.
  - [x] **P15.1a** The manifest and the iPhone. `/manifest.webmanifest` from the tokens and the owner's icons (docs/web.md), the head's links and `theme-color`, and production tests. Seen in the iOS Simulator (iPhone 18 Pro, Safari): Add to Home Screen offered "Day by Word" with the owner's icon and "Open as Web App"; the icon opened Today standalone, without Safari's bar.
  - [ ] **P15.1b** Installation on Android: Chrome's install prompt and the installed app opening on Today. Needs an Android phone, or an emulator image (a download of a few gigabytes, which an agent makes only with the owner's OK). Check it then, or with P15.6's browser checks.
- [x] **P15.2** The web offline, finished: SvelteKit's service worker (`src/service-worker.ts`) keeps the assets and the active plans' coming weeks, queues marks, and never caches another reader's data.
  - *Result (agent, 2026-11-22):* P8.11's worker (E53: a week of Today, marks queued offline, nothing from `/api/` kept) now also keeps the home page, Plans and a new `/offline` page with each release, shows `/offline` for a page never kept instead of the browser's error, and keeps the `/_app/` files the pages link to (the build listed none, so a kept page opened unstyled after an update until one more online visit); asset paths are absolute (`paths.relative: false`). Seen in the browser pane with the server stopped: Plans and Today (with "You're offline" and its kept cards) opened styled, and an unopened week showed the offline page. Production tests; routes.json version 5.
- [x] **P15.4** Keyboard use throughout, and sharing through the Web Share API with a copy-link fallback. *(Rewritten by D39.)*
  - *Result (agent, 2026-11-22):* **Share this plan** on each plan's page (`ShareButton.svelte`, `share.js`): the Web Share API where the browser has it, else the link copied, else shown selected in a labelled field; hidden without JavaScript. The app's plan page has a ShareLink to the same daybyword.com address (`AppRoute.webURL`). Keyboard: a Tab walk of every page in the browser pane found every control reachable with a visible ring; the gap was Today and History, whose buttons vanish when their HTML is replaced, so `reading.js` now puts focus on the plan's Undo after Mark read and on Mark read after Undo (Undo is described by its "Marked … read"). The web tour presses Tab and Enter for Share, Today and History in Firefox (335 checks); the fallback was seen at 375 px in the browser pane and the share sheet in the iOS Simulator. A real phone's Web Share sheet is not seen yet (P15.6).
- [x] **P15.5** Write `docs/browsers.md`: the support matrix (D30) and what was tested in each browser.
  - *Result (agent, 2026-11-22):* docs/browsers.md: the matrix, what the web app needs (the features `support.js` checks, IndexedDB, the service worker, the CSP), features that depend on the browser (Share, Copy, install, offline, print), a table of every browser test run with its version and date, what is not tested yet, and the by-hand pass at each release. Linked from README.md and docs/web.md.
- [ ] **P15.6** Browser tests for every web flow at phone and desktop widths in Safari and Chrome, with Firefox and Edge checked by hand at each release.
  - *Note (agent, 2026-11-22):* split: Chrome (and Firefox, automated too) are done; Safari's driver refuses a session until "Allow remote automation" is on, which is the owner's setting.
  - [x] **P15.6a** Chrome and Firefox. `scripts/webtour.swift` drives Chrome through its DevTools protocol (no chromedriver: Homebrew's fails Gatekeeper; E60) at 1280, 375 and 320 px, and Firefox at 1280 and 500 px, in light and dark, and both run every web flow at the desktop and the narrowest width: choosing, starting toward a finish date, Copy, part read, Skip, Undo, the welcome back, pause, resume, stop and follow again, the calendar file, the export, and Delete everything. `make tour-web` runs both: 505 checks in Chrome 157, 343 in Firefox 160.
  - [ ] **P15.6b** Safari, on the Mac and in the iOS Simulator: `DBW_WEBDRIVER=safari swift scripts/webtour.swift` once the owner turns on Safari's Settings › Advanced › "Show features for web developers", then Developer › "Allow remote automation" (or runs `safaridriver --enable`, which asks for the Mac's password). Edge, which shares Chrome's engine and is not installed here, stays a check by hand at each release (docs/browsers.md).

## Phase 16: Public pages, legal, and App Store readiness

- [x] **P16.1** The home page: what Day by Word is ("Find your plan. Read your Bible. Keep your place."), the plans actually in the catalog (never promised ones), the independence statement, and the way into Today.
  - *Result (agent, 2026-11-22):* `/` now says what Day by Word is (your own Bible, references never text), how it works (find, read, keep), lists every plan the served catalog holds with its kind and readings (from `planList`, so never a promised one), says no account, ads or tracking with the record kept in the browser, and gives the independence statement in the page itself; Go to Today and Choose a plan lead in. A production test checks it links every catalog plan and no other. Seen in the browser pane at desktop (dark) and 375 px (light), console clean.
- [x] **P16.2** The support page (`/support`): support@daybyword.com, how to report a reading error (plan, assignment, and what is wrong), what is collected, and frequently asked questions.
  - *Result (agent, 2026-11-22):* `/support`: the address (D28), how to report a reading that looks wrong (the plan, the reading's number or date, what is wrong; a `mailto:` with a subject), what is kept (the record in the browser or on the device, the server's metadata-only log with no address, no accounts or analytics, mail to the owner's inbox), and eight questions people ask. Linked from every page's footer and Settings › About on the web, and Settings › About in the app ("Help and support"). In the sitemap, routes.json (version 6), the tour, and docs/urls.md. Seen in the browser pane and in the iOS Simulator's Settings.
- [ ] **P16.3 [OWNER]** The privacy policy and terms, drafted in `docs/legal/` from the real data flows: at 1.0, reading data stays on the device and in the browser, the server keeps none, and there are no analytics (D10, D39). The owner approves them before they are published. *(Rewritten by D39.)*
  - *Note (agent, 2026-11-22):* drafted: `docs/legal/privacy.md` and `docs/legal/terms.md`, each statement checked against the code and the host (the app makes no network requests; the server logs method, route pattern, status and time, kept in the journal at most 30 days; Caddy writes no access log; the database holds only the catalog). Each ends with the owner's questions (the mail provider and retention, how to name the operator, the EULA, governing law). Waiting on the owner's approval; then `/privacy` and `/terms` are built from them.
- [ ] **P16.4** The cookie statement, inside the privacy page: every cookie and browser storage key, what it holds, and why it is strictly necessary. *(Rewritten by D39.)*
  - *Note (agent, 2026-11-22):* drafted inside `docs/legal/privacy.md` ("Cookies and browser storage"): no cookies; the IndexedDB stores, the seven local-storage keys, the session key, the cache and the service worker, each with what it holds and why. Published with P16.3.
- [x] **P16.5** Sources, permissions, and criteria pages, generated from the catalog and `catalog/SOURCES.md`, with every required credit line.
  - *Result (agent, 2026-11-22):* `/sources` lists each plan's source note, review and permissions from the served catalog (an anchor per plan, which its page's Permissions line links to), every cleared source in `catalog/SOURCES.md` that no plan names (read at build time and parsed as the compiler does; a cleared source without words stops the page), with STEP Bible's CC BY credit and link, and the book registry's citations. `/criteria` publishes the criteria, whose words moved into the string table (docs/criteria.md points there). Both are in every page's footer, the app's Settings › About, the sitemap, routes.json (version 7), the tour and docs/urls.md; production tests tie the page to SOURCES.md. Seen in the browser pane, console clean.
- [x] **P16.6** The accessibility statement: WCAG 2.2 AA, what was tested, known gaps, and how to report a barrier.
  - *Result (agent, 2026-11-22):* `/accessibility` states the aim (WCAG 2.2 AA), only what has run (keyboard alone, 320 px reflow, AA contrast in both appearances, state in words, spoken references, the app's AX5 tour screens), the gaps Phase 17 closes (screen readers, the app's other screens at AX5, 400% zoom, forced colors, Bold Text and the rest), and how to report a barrier (a `mailto:` with a subject). To make the keyboard claim true for every page, the web tour now Tabs through each one and checks every visible control is reached with its focus outline, in Firefox and Chrome (505 and 739 checks). Linked from every footer and the app's Settings; routes.json version 8. Update it as Phase 17 lands.
- [ ] **P16.7** The App Store package in `docs/app-store/`: the privacy manifest with accurate required-reason declarations; the privacy label (target "Data Not Collected" without an account, and accurate once accounts exist); age rating; export compliance; name, subtitle, description with the independence statement, and keywords; support and privacy URLs; review notes; and screenshots automated by UI tests in light and dark.
  - *Note (agent, 2026-11-22):* `docs/app-store/README.md` holds the listing (name, subtitle, categories, promotional text, keywords at 93 of 100 characters, a description of what the app does today with the independence statement), the privacy label (Data Not Collected; the app makes no network requests), the manifests checked (UserDefaults is the only required-reason API in the code), age rating, export compliance, content rights and review notes. Still open: the screenshots' UI test (6.9-inch iPhone and 13-inch iPad, light and dark, with real readings) and the privacy policy URL, which waits on P16.3.
- [x] **P16.8** Favicons and icons from the owner's files (D19); custom 404 and 500 pages; and a sitemap.
  - *Result (agent, 2026-11-22):* the icons were already the owner's (`favicon.ico`, the 32 px PNG, the touch and web-app icons, `design/images/manifest.json`), the 404 the site's own, and the sitemap P9.9's (now with the public pages). The 500 page now says plainly that the page could not be shown and nothing is lost, in the layout; `src/error.html`, SvelteKit's last resort, says the same with no stylesheet to fail, in the table's words (a unit test checks). A production test starts a server whose database is out of reach and gets the site's 500 page; seen in the browser pane the same way.
- [x] **P16.9** A link check in `make check`: every internal link resolves, pages validate as HTML, and nothing loads from another host.
  - *Result (agent, 2026-11-22):* `web/test/production/links.test.ts` (in `make check` through `make smoke-web`, E61) crawls the production build with the release catalog from the home page and every page in routes.json: each same-site link and file must answer (redirects followed), every file a page loads must be the site's own (links out to Bible.com and STEP Bible stay allowed), and every page (the 404 and offline pages too) must pass html-validate's `standard` rules. All pass; its first run caught the crawl's own mistake (the component gallery is development-only). html-validate 11.19.0 is the one new development package, recorded in E61.

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

- **2026-11-22, third session:** P12.4 (Siri and Shortcuts, E58), P12.6a
  (iPad sidebar and readable widths), Phase 13 finished (P13.1 week PDF and
  large print, P13.4 calendar export, E59, P13.5 print and export tests),
  P15.1a (installable web app, seen on an iPhone) and P15.2 (offline
  finished). Split: P12.6b (Mac) and P15.1b (Android) wait on the owner.
- **Shipped:** `make check-full` passed; daybyword.com serves 2b906ec;
  TestFlight build 131 (0.1.0, 2b906ec) uploaded, processing at the end of
  the session. The owner asked to stop here: P15.4 was scoped, not begun.
- **Shared code:** `TodaysReading` (apple/Shared) names today's reading
  for the widget and Siri; `ReadableWidth` / `readableRows()` hold every
  screen to 720 points; App Shortcut phrases are `AppShortcuts.xcstrings`,
  kept by `scripts/strings.swift`; calendar files come from two writers
  held to `tests/fixtures/calendar.json`.
- **Web:** asset paths are absolute now (`paths.relative: false`), and the
  service worker keeps the `/_app/` files the kept pages link to; the
  browser pane runs that worker on localhost (AGENTS.md §11).
- **Tests:** the web tour prints the week through Firefox and checks the
  PDF (332 checks); the iPhone UI tests pass with the adaptable tab style.
- **Simulators:** every iPhone simulator was held by other sessions, so
  this session made "DbW iPhone 18 Pro" (1A19E4D3) and used a shut-down
  iPad Air 11-inch; the Mac's load reached 665.
