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

1. Read AGENTS.md first. Then read this whole file once per session.
2. Work the **first open `- [ ]` item in the earliest incomplete phase**,
   skipping items whose gate is still closed and items marked [OWNER] that
   are waiting on the owner personally (AGENTS.md §4). The design session
   (P2.3) is the exception: it is a hard stop, and no further building
   happens until the owner has said the design is final. Items marked
   *(parallel-safe)* may be done in any order within their phase, and Phase
   10 (the launch catalog) may run alongside Phases 9–17.
3. Every feature lands in the app and on the web in the same phase (D37).
4. Inspect the code before trusting a checkbox. Fix drift in either
   direction.
5. Tick a box only when AGENTS.md §7 (definition of done) is met. Commit the
   tick with the work, with the step id in the subject (for example
   `P5.5: ...`).
6. Complete as many items as you can in a session. Before stopping, run
   `make check`, update the **Build status** table, push, and replace the
   **Handoff notes** at the bottom.
7. If an item is wrong, too large, or out of order, do not silently skip or
   delete it. Split it into sub-items (`P5.6a`, `P5.6b`), rewrite it, or add
   a note under it, and say what you changed in the Handoff notes.
8. Record history where the next agent will look for it: a dated *Note* or
   *Result* line under the item it concerns, a new or revised decision in the
   Owner decisions table or `docs/decisions.md`, the evidence in
   `catalog/SOURCES.md`, and the current state in the Handoff notes. Git
   keeps the rest.

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
  at daybyword.com (P8.14). That is when the permission letters of D38 go
  out.

---

## Build status

Update the **Done** column whenever you tick or untick a box. "Items" counts
top-level items; sub-items roll up into their parent.

| Phase | Name | Milestone | Items | Done |
|---|---|---|---|---|
| 0 | Owner foundations | — | 8 | 6 |
| 1 | Repository and toolchain | M1 Foundation | 13 | 12 |
| 2 | Product, design system, and shells | M1 Foundation | 12 | 5 |
| 3 | Scripture references and versification | M1 Foundation | 9 | 0 |
| 4 | Catalog pipeline and rights registry | M1 Foundation | 10 | 0 |
| 5 | The reading engine | M1 Foundation | 13 | 0 |
| 6 | Church calendars and lectionaries | M1 Foundation | 7 | 0 |
| 7 | Hosting at daybyword.com | M1 Foundation | 7 | 0 |
| 8 | Today and the first plans | M2 First light | 14 | 0 |
| 9 | Choosing a plan | M3 Version 1.0 | 9 | 0 |
| 10 | The launch catalog | M3 Version 1.0 | 13 | 0 |
| 11 | Progress and history | M3 Version 1.0 | 6 | 0 |
| 12 | Widgets, notifications, and Apple integration | M3 Version 1.0 | 9 | 0 |
| 13 | Paper, print, and calendars | M3 Version 1.0 | 5 | 0 |
| 14 | Accounts, backup, and sync | M3 Version 1.0 | 8 | 0 |
| 15 | The web app: install, offline, and reminders | M3 Version 1.0 | 6 | 0 |
| 16 | Public pages, legal, and App Store readiness | M3 Version 1.0 | 9 | 0 |
| 17 | Quality hardening | M3 Version 1.0 | 11 | 0 |
| 18 | Version 1.0 launch | M3 Version 1.0 | 9 | 0 |
| 19 | More ways to read | M4 Together | 5 | 0 |
| 20 | Companion plans and reading outside a plan | M4 Together | 5 | 0 |
| 21 | Groups, churches, and families | M4 Together | 8 | 0 |
| 22 | Plan builder and private import | M5 Your own plans | 6 | 0 |
| 23 | More traditions, canons, and languages | M5 Your own plans | 9 | 0 |
| 24 | Apple Watch, Mac, and Android | M6 Everywhere | 5 | 0 |
| 25 | Sustainability | M6 Everywhere | 5 | 0 |
| 26 | Operations and annual maintenance | Ongoing | 9 | 0 |
| 27 | Future directions | Ongoing | 6 | 0 |

**Current state (2026-11-01):** Phase 1 is done except P1.12 (TestFlight,
waiting on the owner), and Phase 2 through P2.6: product rules, the Morning
design with generated tokens and type, the owner's artwork batch, and the
shared components on both platforms. `make check`, `make test-linux`, and
the hosted CI run pass. **Next: P2.7**, the iOS shell; the owner asked for
work to stop after P2.6 this session. Nothing is deployed yet.

---

## The finished product

This section defines what "complete" means, and every phase builds toward
it. When the whole plan is done, Day by Word is:

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
criteria are published, and every item has a permissions record. Historic
prayer-book lectionaries are computed correctly from their own rules,
edition by edition, and the reader can see the rule behind today's
readings.

**Honest progress.** The reader sees assignments completed, recent reading
days, books explored, and the next reading. Plan completion is kept apart
from Bible coverage. A streak is available for those who want one and is
never in charge. Returning after a gap, finishing a book, and keeping a
rhythm you chose are each celebrated quietly.

**Private and yours.** There are no ads, analytics, tracking, or AI features
(D12, D23). On the phone everything works without an account and offline.
Backup and sync between the app and the web are optional and use passkeys,
and export and deletion are available at any time.

**Quiet, readable, accessible.** Text is generous, Dynamic Type works up to
the largest sizes, and VoiceOver, dark mode, and keyboard use on the web are
all supported, to WCAG 2.2 AA. There is no feed, no ranking, and no
dashboard that reads like a performance review. Success can mean opening the
app for ten seconds and spending twenty minutes in the Bible.

**After 1.0.** Further work adds more Bible apps and websites to open
readings in; companion plans (for example a psalm beside the main plan),
with overlaps handled deliberately; reading logged outside any plan; church
and family plans joined by link or QR code, which encourage without
surveillance; a plan builder and private import; and more traditions and
languages as editorial expertise and rights allow.

### Feature map: what others offer, and our answer

This map is drawn from App Store data (Apple's public search API, US store)
and the products' own pages, checked 2026-10-30 (Research finding 1), and
from each app's App Store listing (privacy label, purchases, description,
version notes), checked the same day (P2.2a, `docs/research/competitors.md`).
Ratings change, so re-check them before quoting. Rows marked † still rest
partly on general knowledge and are confirmed on a device in P2.2b.

| Product | What it offers | Our answer (phase) |
|---|---|---|
| **ReadingPlan** (James Price; 4.7 from 199 ratings; since 2009) | A plan catalog, any start date, follow the schedule or go at your own pace, readings opened in online Bible sites or native Bible apps | The closest match to this concept. Our answer is guidance in choosing, calendar-correct lectionaries, the return flow, paper support, and web and app sync (P5, P6, P8, P9, P13, P14) |
| **YouVersion Bible App** (Life.Church; 4.9 from about 13.9 million ratings) † | A vast catalog that includes partner plans, a built-in Bible, "Catch Me Up" (which resets today to the day after the last completed reading), and plans with friends | Fewer, reviewed plans with workloads and limitations; three catch-up choices, each previewed; YouVersion as the first place to open a reading (P5.8, P8.5, P9, P10) |
| **Sola – Bible reading plans** (Samuel Jusaitis; 4.8 from 40) | Custom plans balanced by word count, editable pace, hosted shared plans, rescheduling of missed readings, links to Bible apps, and supporter in-app purchases. Sign-in is by email, and its privacy label lists name, email, user ID, and purchase history used for analytics | Catalog plans balanced by reading time, no sign-in needed, passkeys when syncing, and "Data Not Collected" for local use (P3.7, P10, P14, P16.7) |
| **Read Scripture** (Crazy Love Ministries; 4.8 from 1,770) | A whole-Bible plan with BibleProject videos; optional accounts sync progress; "Data Not Collected" | The videos stay the publisher's; a partnership inquiry (D38) |
| **Through the Word** (4.8 from 5,035) | Guided audio for every chapter, 19 "journeys", group plans, email sign-in; its privacy label declares tracking by identifiers | Audio services as places to open a reading (P19) |
| **One Year Bible Plan + Audio** (4.9 from 3,181) and **Yearly** (4.7 from 357) | One Year Bible Plan: one year plan with built-in text, audio, and streaks. Yearly: several year plans (M'Cheyne, Old and New Testament daily, straight through, and the ACNA 2019 Daily Office, per its version notes), streaks, and a $2.99 a month premium tier | A real choice of plans, including year plans in canonical, five-day, and balanced forms (P10) |
| **My Bible Tracker** (4.6 from 131) and similar trackers | Chapter checklists, several trackers, achievements, and no timed plans | Assignment states (completed, partial, skipped, unread), with coverage kept apart from completion (P5, P11) |
| **Olive Tree** (4.8 from 324,607), **Blue Letter Bible** (4.9 from 360,863), **Logos** (4.9 from 176,972), **Bible Gateway** (3.7 from 10,117) † | Reading plans inside a full Bible reader (confirmed for Olive Tree: "dozens" of plans, progress, daily reminders) | Destinations, not rivals: we open the passage there after 1.0 (P19) |
| **daybyword.org "DayByWord"** (web) | Its own 2026 plan, short built-in plans, custom plans by start date and chapters a day, a monthly calendar, PDF and Excel export, English and Chinese, and quotations from the Recovery Version | An unrelated site with the same name; the owner keeps the name (D2) |

New entrants in September 2026 ("Bible Reading Plan: Pace", "Shepherd: Track
Bible Reading", "Bible-ReadingPlan") show that the category is active.
Being a tracker rather than a Bible reader is not enough difference on its
own.

### Where Day by Word aims to be unusually good

This is a product hypothesis, tested after launch through the beta, support
mail, and opt-in surveys (D12, D25), not a claim that competitors lack every
one of these features.

- **Choosing with confidence.** Every plan explains whom it suits, its
  actual workload, and what it covers, and recommendations come with
  reasons (P9).
- **Schedules that know their kind.** Sequential, deadline, and calendar
  plans each behave correctly, liturgical calendars included (P5, P6).
- **Returning as a normal part of reading.** The welcome-back choices are
  previewed and honest, and history is never rewritten (P5.8, P8.7).
- **Paper and digital as equals.** A physical Bible mode, printable weeks,
  widgets, and notification actions mean the app rarely needs opening (P8,
  P12, P13).
- **Trust.** Accurate readings, dependable reminders, clear permissions, a
  source note on every plan, and privacy by default (P4, P8.8, P16).

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

## Research findings that shape this plan

These were checked on 2026-10-30 unless noted. Agents must re-verify
anything they depend on and record what they checked.

1. **The category** (Apple's search API, US App Store; product pages).
   [ReadingPlan](https://pricejh.com/readingplan/) (James Price; App Store
   4.7 from 199 ratings, first released 2009-11-04) is the nearest existing
   product: a catalog, flexible start dates and pace, and links into Bible
   websites or native Bible apps. Its page does not mention catch-up,
   widgets, reminders, or sync. [Sola](https://apps.apple.com/us/app/sola-bible-reading-plans/id1487787716)
   (4.8 from 40) offers custom plans balanced by word counts, hosted shared
   plans, "Reschedule Missed Readings", supporter purchases, email sign-in,
   and a privacy label that lists name, email, user ID, and purchase
   history (used for analytics) and crash data; iCloud sync is planned, not
   shipped. The [YouVersion Bible App](https://apps.apple.com/us/app/id282935706)
   (4.9 from 13,860,459) has "Catch Me Up", which moves today's reading to
   the day after the last completed day
   ([The Sweet Setup](https://thesweetsetup.com/use-catch-feature-youversions-reading-plans/)).
   Other entries: Read Scripture (4.8 from 1,770), Through the Word (4.8
   from 5,033), One Year Bible Plan + Audio (4.9 from 3,180), Yearly (4.7
   from 357), My Bible Tracker (4.6 from 131), and three new trackers
   released in September 2026. Full Bible apps with plans include Olive Tree
   (4.8 from 324,587), Blue Letter Bible (4.9 from 360,859), Logos (4.9 from
   176,945), and Bible Gateway (3.7 from 10,118). P2.2 deepens this with
   hands-on use.
2. **Name and domains.** **daybyword.com** was registered on 2026-10-30 at
   09:58 UTC through Cloudflare (it expires 2027-10-30) and uses Cloudflare
   nameservers. It had no A or MX records on 2026-10-30 and did not answer
   HTTPS. **daybyword.org belongs to another party** (registered
   2025-01-05, with different Cloudflare nameservers) and serves
   "DayByWord – Your Bible Reading Plan and Daily Guide": its own 2026
   plan, built-in plans, custom plans, a monthly calendar, PDF and Excel
   export, and English and Chinese editions. It quotes the Recovery
   Version, gives a Gmail address and an X account (@DayByWord), and its
   footer says "2026 DayByWord. All rights reserved." Searches of the US App
   Store for "day by word" and "daybyword" found no app of that name. The
   owner has chosen to keep the name without a trademark search (D2).
3. **The repository.** `dunamismax/daybyword` was created on 2026-10-30 at
   10:14 UTC. It is **public** and was empty. `origin` pushes to both
   GitHub and the Codeberg mirror, `codeberg.org/dunamismax/daybyword`,
   which was created the same day (D32, P0.5).
4. **Bible destinations.** YouVersion's `youversion://bible?reference=JHN.3.16`
   scheme is undocumented and may change
   ([a 2013 write-up](https://ben.prose.sh/2013-12-18-youversion-bible-url-scheme)),
   so prefer bible.com web links, which open the app where it is installed.
   Confirm their format, their translation ids, and their range support on
   a device in P8.5. For after launch (P19): Olive Tree documents
   `olivetree://bible/<book>.<chapter>.<verse>` with numeric book ids
   ([OliveTreeUrlExample](https://github.com/OliveTreeBible/OliveTreeUrlExample));
   Logos uses ref.ly links, which open in Logos where it is installed and on
   the web otherwise ([Logos Links Guide](https://support.logos.com/hc/en-us/articles/46165718176397-Logos-Links-Guide));
   an Accordance `accord://` link reportedly brings the app forward without
   navigating to the passage
   ([forum](https://forums.accordancebible.com/topic/7166-custom-url-scheme/));
   Bible Gateway, ESV.org, and Blue Letter Bible take passages in their web
   URLs, but their formats were not checked here. Destinations differ in
   range support (some open only a chapter), so every adapter must state
   what it can open.
5. **Scripture data.** Book ids follow USFM's three-letter codes, which
   cover the deuterocanonical books. Versification differs between
   traditions (English/KJV, Hebrew, Greek, Latin), and Psalm numbering
   differs between the Hebrew and the Greek and Latin traditions for most
   of Psalms 9–147. [STEPBible-Data](https://github.com/STEPBible/STEPBible-Data)
   publishes TVTMS, a mapping of versification traditions, under CC BY 4.0
   with attribution. Older Tyndale House pages list non-commercial terms,
   so confirm the licence of the exact file used (P3.2). For counting words
   internally (never displayed, D13): the **Berean Standard Bible** was
   dedicated to the public domain on 2023-04-30
   ([berean.bible terms](https://berean.bible/terms.htm)); the **World
   English Bible** is public domain ([eBible.org](https://ebible.org));
   the KJV is public domain in the US but under Crown rights in the UK.
6. **Reading time.** Brysbaert's 2019 meta-analysis (*Journal of Memory and
   Language* 109; 190 studies) puts the adult English silent reading rate
   at about **238 words a minute for non-fiction**, and oral reading at
   about **183**. The KJV runs to roughly 780,000 words (P3.6 recomputes
   this from the cleared counting text), so a whole Bible in a year is
   about 2,150 words a day: roughly 9 minutes read silently, or 12 read
   aloud. These are estimates. Reflection, reading aloud, and listening
   change them substantially, and the app says so.
7. **Prayer books and lectionaries** (from the founding brief's research,
   checked by its author on 2026-10-30, with the sources it cites).
   "1612" in early notes most likely means the **1662** Book of Common
   Prayer; a specific 1612 printing would need separate identification.
   "The new one" is ambiguous: The Episcopal Church uses the **1979** book
   ([TEC](https://www.episcopalchurch.org/who-we-are/how-we-worship/book-of-common-prayer/)),
   the Anglican Church in North America publishes the **2019** book
   ([ACNA](https://bcp2019.anglicanchurch.net/)), and England's Common
   Worship is another family again. Daily Office readings differ from the
   readings appointed for Sundays and Holy Communion: The Episcopal Church
   adopted the Revised Common Lectionary for Sundays in 2007 and kept its
   Daily Office Lectionary ([TEC Lectionary](https://www.episcopalchurch.org/worship-prayer/lectionary/)).
   IVP's 1662 International Edition keeps the original Daily Office table,
   while later English printings may carry the 1871 replacement and the
   1922 alternative tables; its own appendix uses the 1961 revision
   ([IVP FAQ](https://www.ivpress.com/pages/content/book-of-common-prayer-international-edition-free-resources-faq)).
   A generic "1662 plan" could therefore give a reader an unexpected
   schedule, so every edition gets its own exact label. The 1979 Daily
   Office Lectionary runs a two-year cycle, with Year One beginning on the
   First Sunday of Advent before odd-numbered years (BCP 1979 p. 934;
   confirm from the page in P6.4).
8. **Rights** (from the founding brief, with its sources; a research
   assessment, not legal clearance). Episcopal News Service recorded the
   1979 book's release into the public domain
   ([ENS, 1979-11-01](https://digitalarchives.episcopalarchives.org/cgi-bin/ENS/ENSpress_release.pl?pr_number=79331)).
   For the 1662 book, the Church of England identifies Crown rights with
   Cambridge as the Crown's patentee
   ([CofE BCP](https://www.churchofengland.org/prayer-and-worship/worship-texts-and-resources/book-common-prayer);
   [CofE copyright](https://www.churchofengland.org/copyright)), so review
   the exact source, intended use, and territories. Anglican House's
   current policy requires permission for apps, free ones included, and
   approves new apps only for substantially different content
   ([permissions](https://anglicanhousepublishers.org/permissions/)). An
   older copyright page is more permissive
   ([2019 copyright page](https://bcp2019.anglicanchurch.net/wp-content/uploads/2019/08/02-Copyright-Page.pdf)),
   so the 2019 book's status is unresolved. The Consultation on Common Texts
   claims the RCL's table of citations and requires permission outside its
   stated exceptions ([CCT](https://www.commontexts.org/rcl/permissions/)).
   YouVersion cannot authorize republication of partner plans
   ([YouVersion](https://help.youversion.com/l/en/article/o8t2xmy9q2-copyright)).
   **M'Cheyne's** Calendar for Daily Readings is dated by its introductory
   letter of 30 December 1842 (St. Peter's, Dundee). Its chart appears in
   Andrew Bonar's *Memoir and Remains* and in *The Works of the Late Rev.
   Robert Murray M'Cheyne* (New York: Robert Carter, 1848–1850), both
   candidate public-domain printings. Modern reprints' typesetting is not
   ours to take: transcribe from a public-domain printing (P10.8). Under US
   law individual facts are not protected, but a selection and arrangement
   with minimal creativity can be (*Feist v. Rural*, 1991). That is why
   every plan, even one made only of references, gets a permissions record.
9. **Apple platforms.** Apple's App Store data for 2026-06-07 (as
   [MacRumors](https://macrumors.com/2026/06/09/ios-26-adoption-stats-wwdc/)
   reported it) put iOS 26 on 86% of iPhones introduced in the last four
   years and 79% of all iPhones. iOS 27 shipped in September 2026. An app
   may have only 64 pending local notification requests at once (an Apple
   engineer on the [Developer Forums](https://developer.apple.com/forums/thread/811171)),
   so reminders must be scheduled in a rolling window. Interactive widgets
   and App Intents (iOS 17 and later) let "Mark read" run from a widget or
   a notification without opening the app. App Review requires in-app
   account deletion wherever accounts can be created (Guideline 5.1.1(v))
   and a privacy manifest; confirm both against the current guidelines in
   P16.7.
10. **The web.** Web Push works for Home Screen web apps on iOS and iPadOS
    16.4 and later and in Android browsers. This is from general knowledge
    and is confirmed in P15.3, so the installable web app can serve Android
    readers until D6 opens.
11. **Privacy law.** Data revealing religious or philosophical beliefs is
    special-category data under the GDPR and the UK GDPR (Article 9), and
    the usual basis for processing it is explicit consent: freely given,
    specific, opt-in, confirmed in a clear statement, separate from other
    consents, and withdrawable
    ([ICO](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/lawful-basis/special-category-data/what-are-the-conditions-for-processing/)).
    Bible reading plans and tradition preferences can reveal religious
    belief, so any reading data held on the server is treated this way
    (D10). Confirm with counsel before commercial release (P16.3).
12. **Swift on the server and elsewhere** (for D5). [Hummingbird
    2](https://hummingbird.codes/news/hummingbird-2) is a rewrite built on
    structured concurrency (its release candidate was announced on
    2024-09-11). The [Vapor 5 roadmap](https://www.infoq.com/news/2024/09/swift-vapor-5-roadmap)
    plans a new HTTP server based on Hummingbird, and no tagged Vapor 5
    release was found as of 2026-10-30, so Vapor 4 remains Vapor's
    production line. Swift.org announced a nightly preview of the Swift SDK
    for Android in October 2025
    ([Swift.org](https://swift.org/blog/nightly-swift-sdk-for-android/)),
    which could one day run `ReadingEngine` on Android (D6). Confirm current
    versions when building (P1.4).
13. **Local toolchain** (this Mac, 2026-10-30): macOS 27.2 on Apple silicon;
    **Xcode 27.2** (27B52) with **Swift 6.4.2**; XcodeGen 2.46.0 (Homebrew);
    mise 2026.10.18; Ruby 4.0.9 and Node 26.12.1 are installed but not used
    by this project. Simulators include iPhone 17, iPhone 17 Pro Max, iPhone
    17e, iPhone Air, and iPad Pro 13-inch (M5).
14. **The owner's server.** The owner's Ubuntu server (`ubuntu-vm`, reached
    over Tailscale) already serves several sites behind a shared Caddy.
    Prayerbook Atlas's public `docs/deploy.md` records its conventions:
    `/srv/www/<domain>` with releases, a shared `storage/`, and an
    environment file; a system user per site; services under systemd; a
    shared deploy lock (`/usr/local/sbin/with-deploy-lock`); ports
    4311–4315 already taken; site files in `/etc/caddy/sites/`; and nightly
    backups carried off the server by the `ubuntu-vm-backup` repository.
    prayerbookatlas.com resolved to 71.215.196.157 on 2026-10-30. Day by
    Word fits beside them by those conventions, and its own scripts are
    written fresh (D22).

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
| D10 | Where personal data lives | **On the device by default; on the server only after explicit, separate consent** ("Keep my plans and progress on daybyword.com"), because reading data can reveal religious belief (Research finding 11). This covers web browser profiles and sync (owner, 2026-10-30). A browser profile is keyed by a random secret in a first-party cookie, holds no name or email, and is deleted after 18 months without use, with notice on the page beforehand. Export and deletion are available at any time. No analytics, advertising, or tracking; nothing sold or shared; no third-party processors. Encrypted off-server backups (P7.5) expire on a published schedule. |
| D11 | Sustainability and pricing | **A free core forever, plus voluntary donations** (owner, 2026-10-30). Free means a useful plan selection, reading progress, ordinary reminders, backup and sync, and personal data export. Paid extras (family organization, advanced personal planning, church administration) are considered only after launch, if readers show they value them, and tested against the supporter model. No ads, ever; no lifetime price. |
| D12 | Measurement | **No analytics, ever** (owner, 2026-10-30). With no pilot (D25), learning comes from the beta (D36), support mail, the aggregate data Apple provides, and opt-in surveys (P18.9). |
| D13 | Bible text in the product | **Never** (owner, 2026-10-30): Day by Word never shows Bible text, now or later. It shows references and opens the reader's own Bible. Word counts from a public-domain text are used internally for workload estimates only. |
| D14 | The launch catalog | **All twelve plans** (owner, 2026-10-30), each subject to editorial and rights review (Phase 10): Gospels at your pace; the Bible in a year (canonical, balanced by reading time); the Bible in a year, five days a week; the New Testament in a year, five days a week; the Story of Scripture (about 50 readings introducing the biblical narrative); a psalm a day; Proverbs through the month; Paul's letters; the deuterocanonical books (for Bibles that include them); M'Cheyne's Calendar for Daily Readings (1842); the 1979 Daily Office Lectionary; and the 1662 Table of Lessons with its monthly Psalter. Not at launch: a chronological plan, contemporary ministry plans, the RCL, and the 2019 Daily Office (Phase 23). Never copy a contemporary publisher's version of a familiar plan because its underlying idea is old. The catalog must stay useful if any requested publisher declines. |
| D15 | Prayer-book plans and their reviewers | **The owner reviews the 1979 and 1662 plans now, as reviewer of record, and a second reviewer who uses each book is sought when possible** (owner, 2026-10-30). Until the owner's review is recorded, those plans are marked "in review" and stay out of release builds. Each is labeled with its exact edition and calendar rule and kept apart from Sunday and Communion lectionaries. The later English tables (1871, 1922, 1961) are separate plans, never merged under 1662. |
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
| D37 | Build order | **The app and the web together** (owner, 2026-10-30): each feature lands on both in the same phase. |
| D38 | Outside permissions | **Pursue all four once a usable build exists** ([GATE DEMO]; owner, 2026-10-30): Cambridge University Press (the 1662 tables in the UK), Anglican House (the 2019 Daily Office as a references-only schedule), the Consultation on Common Texts (the RCL and its daily readings), and partnership inquiries to ministries whose plans readers ask for (for example BibleProject and the Navigators), with no suggestion of existing agreement. Agents draft each letter, and the owner confirms it before it is sent in the owner's name. |

---

## Engineering foundations

`docs/decisions.md` (P1.2) records each foundation with its reasons.

1. **One repository, one gate.** The app, the server, the Swift packages,
   the catalog, and the tests live together, and `make check` runs every
   check. Nothing is ticked unless it passes.
2. **The plan is not the enrollment, and neither is the record.** A *plan
   version* holds its edition, permissions, references, and calendar rules,
   and is immutable once published. An *enrollment* holds a reader's start,
   behavior, reading days, sessions, reminders, way of reading, and the plan
   version it follows. The *journal* holds what the reader actually did and
   when. Changing a schedule never rewrites a plan or erases a record.
3. **An event journal.** Reading records are append-only events (completed,
   partly completed, skipped, undone, logged late, enrollment changed,
   catch-up applied, calendar rejoined), each with a UUIDv7 id, the civil
   date it concerns, the instant and time zone it happened, and its device.
   State is a deterministic fold over the events, and undo is an event too.
   Sync exchanges events idempotently, so retries never double-count a
   reading. Only a reader's own deletion request removes events.
4. **One engine, everywhere.** `ReadingEngine` (a Swift package using
   Foundation only) is the single implementation of references, schedules,
   progress, and reminder rules. The app, its widgets and other extensions,
   the server, and the catalog compiler all use it. `docs/engine.md` (P5.1)
   specifies it, and table-driven cases pin it. Its tests run on macOS and
   on Linux, because the server runs it on Linux and both must give the
   same answers. No other code (app views, server routes, JavaScript, or
   SQL) reimplements engine logic.
5. **Calendars computed once, at compile time.** The catalog compiler (the
   `catalog` tool in `Packages/CatalogCompiler`) evaluates every church-year
   and lectionary rule and writes dated appointments into the catalog for a
   window of years (2020–2045 at first, extended with each catalog
   release). The engine only looks appointments up by date, so the hardest
   rules live in one place with golden tests.
6. **A compiled, versioned catalog.** `catalog/` (plain-text plans, rule
   tables, scripture data, and `SOURCES.md`) compiles into a deterministic
   `Catalog.sqlite` with a schema version and a checksum. It is bundled in
   the app, opened read-only by the server, and later delivered to the app
   as a signed catalog update. The compiler refuses unverified references,
   false coverage claims, and uncleared sources.
7. **Civil dates, not instants.** Plans and enrollments speak in civil dates
   (a `CivilDate` of year, month, and day), never a `Date` standing for a
   day. The reader's "today" is resolved once, at the edge, from their
   device's time zone. Reminders are wall-clock times with an IANA time
   zone, which survives daylight saving time and travel.
8. **Local-first app, server-backed web.** The app works fully offline
   without an account. The web keeps progress on the server only with
   consent (D10), caches the active plans for offline reading, and queues
   marks made offline.
9. **SQLite everywhere.** The system `SQLite3` library is used through
   `ReadingData`'s own small wrapper on iOS and on Linux, for the catalog,
   the app's journal, and the server's databases (accounts, browser
   profiles, synced journals, push subscriptions). WAL mode is used on the
   server, with migrations versioned in code.
10. **Few dependencies.** The Apple app has zero third-party runtime
    dependencies, and its approved build tools are XcodeGen and Apple's
    `swift format`. The server depends on Hummingbird 2 and the Swift Server
    Work Group packages it brings (SwiftNIO, swift-log, Service Lifecycle,
    HTTP Types); every other package (HTML templating, WebAuthn, web push,
    jobs) needs a decision entry, and every package is pinned in
    `Package.resolved`. The web's JavaScript is the project's own vanilla ES
    modules, with no npm, no bundler, and no third-party scripts. Never add
    analytics, advertising, tracking, crash-reporting, affiliate,
    remote-font, or CDN code.
11. **Modern browsers** (D30). The server renders semantic HTML, and the
    project's own JavaScript adds the web app's interactivity. The targets
    are the current and previous major versions of Safari, Chrome, Firefox,
    and Edge, and older browsers get a plain notice. A strict Content
    Security Policy allows nothing from other hosts.
12. **Shared design tokens.** `design/tokens.json` generates both the Swift
    color assets and the web's `tokens.css`, and tests check contrast and
    ban raw colors.
13. **Our own simple formats.** Plans use `key: value` front matter and a
    tab-separated schedule, rule tables are JSON, and our code parses them.
14. **A date override for tests.** Debug builds accept `-today YYYY-MM-DD`,
    and the development server accepts `?today=YYYY-MM-DD`, so tests and
    screenshots can pin any day.
15. **Internationalized from the start.** Every interface string goes
    through a String Catalog on Apple platforms and the server's string
    tables on the web, English first.

### Architecture at a glance

```
┌──────────────── iPhone and iPad (SwiftUI, Swift 6) ────────────────┐
│ Today · Plans · Progress      Widgets · Notification actions ·     │
│                               App Intents · (later) Watch          │
│   ReadingEngine (references, schedules, progress, reminder rules)  │
│   ReadingData (SQLite: catalog and journal; sync client)           │
└───────────────────────────────┬────────────────────────────────────┘
                                │ HTTPS /api/v1 (optional sync, D8)
┌───────────────────────────────▼────────────────────────────────────┐
│ ubuntu-vm: Caddy → DayByWordServer (Hummingbird 2, systemd)        │
│   public catalog and plan pages · web app (Today, Plans, Progress) │
│   sync API · passkey accounts · calendar feeds · web push          │
│   the same ReadingEngine and ReadingData                           │
│   shared/storage/*.sqlite (reader data) · Catalog.sqlite (read-only)│
└────────────────────────────────────────────────────────────────────┘
catalog/ (plans, rules, scripture data, SOURCES.md)
   └─ swift run catalog ──► Catalog.sqlite ──► app bundle + server release
```

### Repository layout (planned)

```
AGENTS.md  BUILD.md  README.md  LICENSE  Makefile  .swift-version
catalog/                  plan sources, rule tables, scripture data, SOURCES.md
Packages/ReadingEngine/   references, schedules, progress, reminder rules
Packages/ReadingData/     SQLite wrapper, catalog reader, journal, sync client
Packages/CatalogCompiler/ the `catalog` tool: validate, compute calendars, write Catalog.sqlite
Server/                   DayByWordServer (Hummingbird 2): pages, web app, API, templates, assets
apple/                    project.yml, App/, Widgets/, AppTests/, AppUITests/, Config/
design/                   tokens.json, image-prompts.md, the owner's image files
docs/                     product, engine, catalog format, editorial, design, deploy, decisions …
deploy/                   the systemd unit, Caddy site, and deploy, backup, and check scripts
scripts/                  development helpers (simulator choice, token generation)
research/                 gitignored downloads and working files
```

### Milestones

- **M1 Foundation** (Phases 1–7): the app and the server run in the chosen
  design; references, the catalog, the engine, and the lectionaries are
  correct and tested; daybyword.com is deployed and marked as in
  development.
- **M2 First light** (Phase 8): Today, marking, reminders, the return flow,
  and the first three plans, on TestFlight and at daybyword.com. This opens
  [GATE DEMO].
- **M3 Version 1.0** (Phases 9–18): choosing a plan, the launch catalog,
  progress, widgets, print, sync, the web app, legal pages, hardening, the
  beta, and launch.
- **M4 Together** (Phases 19–21): more ways to read, companion plans,
  reading outside a plan, and groups.
- **M5 Your own plans** (Phases 22–23): the plan builder, private import,
  and more traditions and languages.
- **M6 Everywhere** (Phases 24–25): the Watch, Mac, Android, and
  sustainability.
- **Ongoing** (Phases 26–27): operations, yearly verification, and future
  directions.

---

## Phase 0: Owner foundations

- [x] **P0.1 [OWNER]** Answer the open decisions. *(Owner, 2026-10-30: D1–D38 answered in an interactive session and recorded above.)*
- [x] **P0.2 [OWNER]** Create the repository. *(Owner, 2026-10-30: `dunamismax/daybyword`, public; see D4.)*
- [x] **P0.3 [OWNER]** Register the domain. *(Owner, 2026-10-30: daybyword.com at Cloudflare, registered 09:58 UTC, expiring 2027-10-30.)*
- [x] **P0.4 [OWNER]** DNS and mail in Cloudflare: A records for `daybyword.com` and `www.daybyword.com` pointing at the server (the address prayerbookatlas.com uses, Research finding 14), DNS only and not proxied, and Email Routing with a catch-all to the owner's inbox (D28). *(Owner, 2026-10-30.)*
  - *Result (agent, 2026-10-30):* `dig` against 1.1.1.1 shows `daybyword.com` and `www.daybyword.com` as A 71.215.196.157 (the server's own address, so DNS only, not proxied) with no AAAA; MX `route1`–`route3.mx.cloudflare.net`; and SPF `v=spf1 include:_spf.mx.cloudflare.net ~all`. The catch-all rule itself cannot be seen from outside; the first message to support@daybyword.com will confirm it.
- [x] **P0.5 [OWNER]** Codeberg (D32): create `dunamismax/daybyword` on Codeberg and add its push URL to `origin`. *(Owner, 2026-10-30: repository created, public, at 10:14 UTC.)*
  - *Result (agent, at the owner's request in chat, 2026-10-30):* `origin` now has two push URLs, `https://github.com/dunamismax/daybyword.git` and `git@codeberg.org-dunamismax:dunamismax/daybyword.git`, as Beautiful Corner does. `git push origin main` updated both, and both remotes' `main` matched the local `80b1cea`.
- [x] **P0.6 [OWNER]** Make sure Xcode on this Mac is signed in to the Apple ID of the owner's individual Developer Program membership (D33). Agents do the rest (P1.12). *(Owner, 2026-10-30.)*
  - *Result (agent, 2026-10-30):* Xcode's account settings show team `D9QMP3LP8H`, type Individual, not a free provisioning team, and the keychain holds one valid Apple Development signing identity for it.

When the first usable build exists:

- [ ] **P0.7 [GATE DEMO]** Draft the four letters of D38 in `docs/owner-drafts/`, each describing the app, the exact use, the attribution, and the demo, generic enough to sit in a public repository (D4).
- [ ] **P0.8 [OWNER] [GATE DEMO]** The owner confirms each letter. Agents send it from the owner's address, or the owner sends it, and agents record each response's status in `catalog/SOURCES.md`. The letters themselves stay off the repository.

## Phase 1: Repository and toolchain

- [x] **P1.1** Add `.gitignore`: Xcode user data, DerivedData, `build/`, `.build/`, `.swiftpm/`, the generated `*.xcodeproj`, `apple/Config/Secrets.xcconfig`, `.env*`, `*.p8`, `*.p12`, `*.mobileprovision`, compiled catalogs, local server databases, `research/`, `screenshots/`, and `.DS_Store`.
- [x] **P1.2** Add `LICENSE` (all rights reserved, D4) and create `docs/decisions.md`, a numbered, append-only decision log seeded with the Engineering foundations, D5's reasoning, and the no-tracking rule.
- [x] **P1.3** The packages `Packages/ReadingEngine`, `Packages/ReadingData`, and `Packages/CatalogCompiler` (an executable named `catalog`): Foundation only and Linux-compatible (no UIKit, SwiftUI, or other Apple-only frameworks), each with one passing Swift Testing test. Add a static guard on their imports.
- [x] **P1.4** The server package `Server/` (`DayByWordServer`, Hummingbird 2 at its current release): configuration from the environment, structured logging, graceful shutdown, `/up`, and a placeholder home page, depending on the local packages by path, with tests through HummingbirdTesting. Record a decision entry for each dependency, including the HTML templating choice (for example the Hummingbird project's Mustache library, or a Swift HTML DSL), and pin them all.
- [x] **P1.5** The Apple project, `apple/project.yml` (XcodeGen): `App` (iPhone and iPad), a `Widgets` extension, `AppTests`, and `AppUITests`; Swift 6 language mode, complete concurrency checking, and warnings as errors; settings in `Config/Base.xcconfig`, with the signing team in the gitignored `Secrets.xcconfig` (an example is committed); identifiers from D1; deployment target iOS 26 (D7). It links `ReadingEngine` and `ReadingData`.
- [x] **P1.6** A pinned toolchain: `.swift-version` (6.4.2 to begin with) used on this Mac, in CI, and on the server (through swiftly). `make test-linux` builds and tests the packages and the server in the official Swift container when a container runtime is present; deploys run the same tests on the server (P7.2).
  - *Note (agent, 2026-10-30):* the official image had no 6.4.2 tag yet, so the container installs the pinned toolchain through swiftly, as the server will (docs/decisions.md E21). First run: all four packages pass on Ubuntu 24.04 (aarch64) with Swift 6.4.2.
- [x] **P1.7** The top-level `Makefile`, with a one-line description for each target: `generate`, `catalog`, `build`, `test-packages`, `test-server`, `test-app`, `test-linux`, `run` (build, boot, install, and launch through `simctl`), `serve` (the server on localhost with a development catalog), `screenshot`, `check` (lint, catalog, package, server, and app tests), `deploy`, and `clean`.
- [x] **P1.8** Formatting: `swift format` with a committed `.swift-format`, linted by `make check`, and a short style note for the project's JavaScript and CSS in `docs/web.md`.
  - *Note (agent, 2026-10-30):* `.swift-format` is the tool's default with four-space indentation and 120-column lines. `make format` rewrites in place.
- [x] **P1.9** `scripts/sim-destination.sh` picks the newest available iPhone simulator, and `SIM_DEVICE` overrides it. Never hard-code a device.
  - *Result (agent, 2026-10-30):* it picks the newest runtime, then the newest iPhone generation, preferring the standard model, then Pro, Pro Max, Air, and e (here, iPhone 18 Pro on iOS 27.2). `SIM_DEVICE` takes a name or UDID and fails clearly when nothing matches; `--udid` and `--name` print just those.
- [x] **P1.10** First light on both platforms: the app launches to a placeholder Today, and `make serve` answers `/` and `/up`. Check both in the simulator and the browser, in light and dark.
  - *Result (agent, 2026-10-30):* `make run` launches the app to the placeholder Today on the iPhone 18 Pro simulator (iOS 27.2), checked in light, dark, and the largest accessibility text size (AX5). `make serve` compiles the development catalog, opens it, and answers `/` (200, HTML) and `/up` (200, `OK`); the in-app browser showed the home page at 1280 px and 375 px wide, light and dark, with no console errors or CSP violations.
- [x] **P1.11** GitHub Actions on manual dispatch (D31): a macOS job (Xcode 27, `make check`) and a Linux job (the Swift container: packages and server). Tick after the first hosted run passes.
  - *Result (agent, 2026-11-01):* the macOS job runs on GitHub's `xcode-27` image with Xcode 27.2 selected. The first two runs failed on Linux because the runners could not read swift.org's key file (decision E22); run 41298521967 passed both jobs.
- [ ] **P1.12** The TestFlight path (D33): `make archive` and `make testflight` (a signed Release archive with the release-checked catalog), a first privacy manifest, the App Store Connect record with D1's bundle ID, and `docs/release.md`. Tick after the first build is processed and installs through TestFlight.
  - *Note (agent, 2026-10-30):* `make archive` builds a Release archive (build 14), but signs it only with the development identity and the wildcard team profile. `make testflight` stops at "Failed to Use Accounts": xcodebuild cannot read the Xcode account's credentials from the keychain ("missing Xcode-Username"), so it cannot create the distribution certificate and App Store profile. Waiting on the owner for four things: re-sign in to the Apple ID in Xcode → Settings → Accounts; the App Store Connect record for `com.daybyword.app` (or permission to create it in the owner's signed-in session); an app icon (D19; App Store Connect rejects uploads without one); and installing the processed build from TestFlight on a device.
  - *Update (2026-11-01):* the requested app icon is now registered and compiles (P2.3). The account, distribution profile, App Store Connect record, processed upload, and owner-device installation remain unverified; P1.12 stays open.
  - *Result (agent, 2026-11-01, later):* xcodebuild now reads the account. `make archive` built build 25 (`f2c4656`); Xcode's Distribute App created the App Store Connect record (Apple ID 6829425132, SKU `com.daybyword.app`, named "DayByWord" by Xcode, then renamed "Day by Word" with the subtitle "Your Bible reading companion" in App Information); `make testflight` then exported and uploaded it ("Upload succeeded"). With the owner signed in to App Store Connect in the in-app browser, the internal group *Owner* was created with automatic distribution and the owner's two Apple IDs invited. Waiting on the owner to install build 25 from TestFlight on a device; tick when it installs.
- [x] **P1.13** Update `README.md`: prerequisites confirmed on this Mac, a quick start that works from a clean checkout, and the real layout.
  - *Result (agent, 2026-10-30):* `make check` passed from a fresh clone with no generated project, no secrets, and no build products.

## Phase 2: Product, design system, and shells

- [x] **P2.1** Write `docs/product.md`: the three sections and Settings, navigation on both platforms, the three schedule behaviors in reader-facing words, the return flow, tone rules (AGENTS.md §3), no guilt mechanics, privacy by design, physical Bible mode, and what each surface (app, widget, notification, web) does.
- [ ] **P2.2** A hands-on competitive teardown: use ReadingPlan, Sola, YouVersion's plans, Read Scripture, Through the Word, Yearly, My Bible Tracker, and one Bible app's plans (Olive Tree or Logos) on a device. Record onboarding, catalog depth, missed-day behavior, links out, widgets, reminders, privacy labels, and prices in `docs/research/competitors.md`, confirm the † rows, and update the feature map.
  - *Note (agent, 2026-10-30):* split in two, because App Store apps cannot be installed in the iOS Simulator and this session had no physical device.
  - [x] **P2.2a** From the App Store listings: ratings, prices and purchases, privacy labels, features, and version notes for every app named here, recorded in `docs/research/competitors.md`, with the feature map updated and four † rows confirmed.
  - [ ] **P2.2b** On a device: onboarding, missed-day behavior in practice (YouVersion's "Catch Me Up", Sola's rescheduling, ReadingPlan's pace), links out, widgets, and reminders, confirming the remaining † rows. Needs a session with an iPhone that may have these apps installed. Nothing later depends on it.
- [x] **P2.3 [OWNER]** The design session (D18), **a hard stop**: agents draw the three directions as screen mockups (Today, a plan page, and Progress in each, light and dark, at phone and desktop widths, with placeholders where images would go, D19), show them to the owner, and then **stop and wait**. Nothing else is built until the owner has chosen, refined the choice over as many rounds as the owner wants, and said the design is final (owner, 2026-10-30). Then agents record the choice in D18 and write `docs/design.md` and `design/tokens.json`. Image needs go to `design/image-prompts.md` (D19).
  - *Result (agent, 2026-11-01):* the three directions were drawn on a Design canvas on 2026-10-30 (an overview, and Bookmark and Morning in full; Desk's Today only, since the owner chose before the rest was drawn). The owner chose **Morning** on 2026-11-01 and asked for building to continue through P2.6. Its boards are kept in `design/mockups/`; `docs/design.md`, `design/tokens.json`, and `design/image-prompts.md` are written. Further refinement rounds remain open to the owner.
  - *Artwork delivery (owner request, 2026-11-01):* light, dark, and tinted app icons; raster and single-color SVG marks; favicon, touch, and maskable web icons; a sharing image; and twelve optional plan covers. Register the app icon and stage web exports without claiming the future catalog or web pages are complete.
    - *Result (2026-11-01):* canonical files, exact prompts, and checksums are in `design/images/`. The app's `AppIcon` set compiles and was checked on the simulator Home Screen in default, dark, and tinted styles, with its accessible name verified. All covers are 1600 × 900 and below 300,000 bytes (largest 184,688); the maskable motif fits the safe circle. `make check` and `make test-linux` pass. All web exports serve with matching checksums; the sharing image was reviewed in the in-app browser without console or CSP errors. Normal and AX5 app launch were checked; no new reader controls were added. Existing App Intents metadata-extraction tool warnings remain unrelated to the asset catalog. No upload or deployment was attempted.
- [x] **P2.4** Generate the Swift color assets and the web's `tokens.css` from `design/tokens.json` by a script, so the two cannot drift. Test that every text pair in `docs/design.md` meets WCAG AA in light and dark, and that no view or stylesheet writes a raw color.
- [x] **P2.5** Type: system faces for the interface, and at most one self-hosted, openly licensed book face for references if D18 calls for one (recorded in `catalog/SOURCES.md`). A type scale that includes a **desk-glance reference size**, scaling with Dynamic Type to AX5 on Apple platforms and in `rem` on the web.
  - *Result (agent, 2026-11-01):* Morning uses the system sans only, so no book face is needed. The scale (`design/tokens.json`, `TypeScale`) puts the desk-glance reference at 38 pt relative to Large Title (72 px on the desktop web). Checked at AX5 in the simulator and at phone and desktop widths in the browser.
- [x] **P2.6** Shared components on both platforms: the reference block (large, selectable, copyable, and read well by VoiceOver: "Mark, chapter 4, verses 1 to 20"); the assignment row with its state (completed, partial, skipped, unread, always in words or symbols as well as color); the plan card; the workload line ("about 12 minutes; estimates vary"); the source note; the sample week; the preview-before-change sheet; the undo banner; and empty, loading, offline, and error states.
  - *Result (agent, 2026-11-01):* the app's components are in `apple/App/Components/` (a debug gallery opens with `-componentGallery`) and the web's in `Server/Sources/DayByWordWeb/Components.swift` with styles in `site.css` (a gallery at `/dev/components` in development only). References take a display and a spoken form, which the engine's formatter will supply (P3.4); statuses always carry a word and a symbol. Checked in the simulator in light, dark, and AX5 (a UI test confirms the spoken labels), and in the browser at 1280 and 375 px, light and dark, and 200% text with no horizontal scrolling. Copy reference's clipboard write could not be exercised in the built-in browser, which refused clipboard access; its fallback (selecting the reference) was. A screen reader was not run by hand.
- [ ] **P2.7** The iOS shell: three tabs (Today, Plans, Progress), each with its own `NavigationStack`, and Settings from a toolbar button. Restore the selected tab and paths on relaunch, and route every destination through an `AppRoute` with the `daybyword://` scheme.
- [ ] **P2.8** The web shell: server-rendered layouts with header navigation (Today, Plans, Progress, Settings); a footer with the independence statement ("Day by Word is independent and not affiliated with any church or denomination"); semantic HTML; the project's own JavaScript modules; a strict CSP and Permissions Policy; responsive pages from 320 px to a wide desktop; and the plain notice for unsupported browsers (D30).
- [ ] **P2.9** Write `docs/urls.md`: readable, stable, shareable URLs (`/plans`, `/plans/<id>`, `/plans/<id>/week?start=YYYY-MM-DD`, `/today`, `/progress`, `/settings`). Route every placeholder by it, and mirror it in the app's routes for later universal links (P12.8).
- [ ] **P2.10** Every interface string through a String Catalog (Apple) and the server's string tables (web), English only for now, with tests that find untranslated text and missing keys.
- [ ] **P2.11** The Settings shell: appearance (Automatic, Light, Dark), reference text size, about with the independence statement, and the running version (the build or the deployed commit).
- [ ] **P2.12** Tours: an iOS UI test, and web browser tests through WebDriver (`safaridriver` ships with macOS; a decision entry records the client), that visit every section in light and dark and save screenshots to gitignored folders.

## Phase 3: Scripture references and versification

All of this lives in `ReadingEngine`, with table-driven tests that run on
macOS and Linux.

- [ ] **P3.1** The book registry in `catalog/scripture/books.json`: USFM ids; canonical orders (the 66-book Protestant order, the Catholic order, and the Greek Orthodox order), with each book's membership by canon; names and abbreviations under each naming convention (D29); and the sources for all of it.
- [ ] **P3.2 [RIGHTS]** Versification data: chapter and verse counts under the English (KJV) scheme as the default, and the Hebrew, Greek, and Latin schemes mapped from TVTMS (Research finding 5). Confirm the licence of the exact file, record attribution in `catalog/SOURCES.md`, and credit it on the sources page.
- [ ] **P3.3** The reference model: a passage (book, start chapter and verse, end chapter and verse, versification); multiple passages; whole chapters; ranges across chapters; partial verses (`a` and `b`); optional verses; alternatives ("either … or …"); and the source's own displayed wording, kept wherever normalizing would lose meaning.
- [ ] **P3.4** The parser and formatter: at least 2,000 cases drawn from the real citation styles of the launch plans and lectionaries (for example "Isa 40:1-11", "Ps 119:1-24", "Luke 2:1-14(15-20)", "Ecclus 44:1-15", "1 Kgs 19", "Song 2"), including every way they can fail.
- [ ] **P3.5** Verse sets: union, intersection, and difference of passages under a versification, giving unique coverage, repeats, and partly read chapters. This underlies coverage (P11.4) and overlap detection (P20.2).
- [ ] **P3.6 [RIGHTS]** Word counts per verse from one cleared public-domain text (BSB or WEB, Research finding 5), stored as numbers only and never as text (D13), with the counting method documented.
- [ ] **P3.7** Workload estimates: minutes from words at 238 a minute silent and 183 aloud (Research finding 6), shown as a rounded range with the plain caveat that reflection, reading aloud, and listening change them. Add the minimum, median, and maximum per plan.
- [ ] **P3.8** Psalm numbering: map Hebrew numbering to Greek and Latin, display both wherever a plan uses the numbering the reader's Bible does not, and add tests for every psalm that differs.
- [ ] **P3.9** Write `docs/scripture.md`: books, canons, names, versification, the reference grammar, verse sets, word counts, and their sources.

## Phase 4: Catalog pipeline and rights registry

- [ ] **P4.1** Give `catalog/SOURCES.md` a documented schema, with one entry per source and plan: id, title, exact edition, creator or owner, where it was obtained (URL or scan), public-domain rationale or permission evidence, attribution required, permitted territories, commercial terms, adaptation rights, offline rights, print and export rights, whether AI use is permitted, what was checked, the review date, and status (`cleared`, `pending`, `rejected`, `wanted`, `reference`). Seed it with the candidates in Research findings 5–8 and a **Wanted** section for D14's later plans and D38's letters.
- [ ] **P4.2** Write `docs/catalog-format.md`. Plan files use `key: value` front matter (id, title, edition, version, creator or source, summary, who it suits, schedule kind, permitted behaviors, sessions as the source names them, reading days, cycle length, coverage claim, canon assumed, books included, repeats, optional and omitted material, tradition label, limitations, instructions, source note, rights id, review status) and a tab-separated schedule body. JSON rule tables cover calendar plans. Write the rules for stable assignment ids.
- [ ] **P4.3** The compiler (`swift run catalog`, called by `make catalog`): parse and validate `catalog/`, verify every reference against its versification through `ReadingEngine`, and write a deterministic `build/catalog/Catalog.sqlite` with a schema version, a manifest, a checksum, and an FTS5 index of plan metadata. It fails on unknown sources, duplicate ids, unresolved references, and plans without a review status. Release mode fails on uncleared sources, and `--allow-pending` downgrades that to a warning in development.
- [ ] **P4.4** Claims checked against the facts: the compiler computes each plan's unique coverage, repeats, optional passages, and omissions, and refuses a claim the schedule does not support. A "whole Bible" claim must cover every verse of its stated canon, and a lectionary never inherits a whole-Bible claim because it lasts a year. The computed facts feed the plan page.
- [ ] **P4.5** The rights guard: each plan's permitted uses (catalog listing, full schedule in the app, offline, print and export, adaptation, territories, commercial use) are compiled into the catalog, and the app and the server enforce them. For example, printing is unavailable where export is not permitted, and an adaptation is unavailable where adaptation is not.
- [ ] **P4.6** Plan versions: a published version is immutable; corrections make a new version with a changelog, explaining material corrections and keeping original appointments available; assignment ids stay stable or are mapped; an enrollment stays on its version until the reader moves, with a preview of what changes. The compiler checks the rules.
- [ ] **P4.7** External directory entries: a plan described with its publisher's link and no schedule, labeled as an outside plan so it never looks hosted.
- [ ] **P4.8** Integration: `make catalog` feeds the app bundle (`apple/App/Resources/Catalog.sqlite`, gitignored) and the server (opened read-only from the release). A missing catalog fails clearly. An integrity suite in `make check` covers unique ids, resolved references, registered and cleared sources, and no empty assignments.
- [ ] **P4.9** Write `docs/criteria.md`, the published selection criteria: traceable source, verified references, transparent coverage, realistic workload, clear instructions, and a documented basis for reuse, with limitations stated alongside advantages. It becomes a public page in P16.5.
- [ ] **P4.10** Write `docs/editorial.md`: review levels (`checked`, meaning automated validation passed; `reviewed`, meaning an editorial review against the source; `expert`, meaning the owner's or another named reviewer's review is recorded, as D15 requires for prayer-book plans); two independent passes against page images for any transcribed plan; how plan descriptions are written and checked against AGENTS.md §3; and the errata process for readers' reports.

## Phase 5: The reading engine

`ReadingEngine` is the only implementation (Engineering foundation 4). The
specification comes first, then the cases, then the code.

- [ ] **P5.1** Write `docs/engine.md`, the specification. It covers plan versions, assignments, sessions, enrollments, the journal and its event kinds, assignment states, the three behaviors, reading days and rest days, pausing, late logging, undo, partial completion, skips, catch-up options and previews, rejoining, changing an enrollment, progress measures, and reminder rules. Each rule comes with a worked example, and the plain-language wording the reader sees appears beside the formal rule.
- [ ] **P5.2** The case format and runner: table-driven JSON cases (catalog fixture, enrollment, events, today, expected output) in `ReadingEngine`'s tests, using invented plans with invented references and never a real plan's schedule. The same cases run on macOS and on Linux (`make test-linux`, the CI Linux job, and each deploy).
- [ ] **P5.3** `CivilDate`, written fresh (D22): weekdays, day arithmetic, the nth weekday, the Julian Day Number, and conversion at the edge to and from Foundation dates in a given time zone, with exhaustive tests.
- [ ] **P5.4** The journal: event kinds, UUIDv7 ids, and a deterministic fold to state that gives the same result in any arrival order. Duplicate events are no-ops, and undo and redo are events. Cases cover a double tap, a retry, a mark made offline on two devices, and recovery from an accidental completion.
- [ ] **P5.5** **Continue at my pace**: the next unread assignment is next; the projected finish follows the reader's recent pace and reading days; five-day plans keep rest days intentional; "ahead" and "behind" are stated neutrally, and only when useful.
- [ ] **P5.6** **Work toward a finish date**: the workload per reading day is computed before the reader accepts. Redistribution stays within a limit the reader sets and is previewed before it applies. An unrealistic target is met with a later date or a narrower plan, and readings are never silently omitted.
- [ ] **P5.7** **Follow the calendar**: today's appointment comes from the dated table; missed appointments stay in history as unread; rejoining marks nothing complete; pausing reminders never pauses the calendar; a personal adaptation, where the plan permits one, is labeled.
- [ ] **P5.8** **Return after a break**: detect a gap against the enrollment's reading days, then offer the choices that apply (continue from the next unread passage, redistribute outstanding sequential readings, rejoin today's calendar), each with an exact preview. Applying a choice is an event.
- [ ] **P5.9** Sessions and multi-reading days: morning and evening (and M'Cheyne's "Family" and "Secret" readings), each with its own state; a day is complete only when its sessions are.
- [ ] **P5.10** Changing an enrollment (reading days, start date, behavior, sessions, plan version) without deleting history, with the effect previewed first.
- [ ] **P5.11** Progress measures: assignments completed, recent reading days, books explored, and the next reading. Unique coverage follows an explicit canon and counting method, partly read chapters count as partial, and repeated passages never inflate coverage. Plan completion is reported apart from coverage. The optional streak (D17) is measured against the reader's own reading days.
- [ ] **P5.12** Reminder rules: from enrollments, settings, the time zone, and the journal, compute the next fire times, honoring selected days, morning and evening sessions, snooze, quiet hours, a maximum per day, stopping once a session is complete, and the 64-request window (Research finding 9). Cases cover daylight saving changes and travel across zones, and they run on Linux too, since web push uses the same rules.
- [ ] **P5.13** Performance: today's view for ten enrollments over five years of events computes within a measured budget on a phone (start at 20 ms) and on the server, recorded in `docs/performance.md`.

## Phase 6: Church calendars and lectionaries

All of this happens at compile time in `CatalogCompiler` (Engineering
foundation 5). Cite the governing source, book and page, for every rule in
`docs/calendar-rules.md`, and label any rule without a printed source as an
"app convention", with the reason.

- [ ] **P6.1** The church year, written fresh (D22): Western Easter by the Gregorian computus, tested for 1583–4099 against an authoritative table (Easter falls between 22 March and 25 April), and the movable observances each launch book needs (Advent Sunday, the Sundays after Epiphany and how surplus Sundays are handled, Septuagesima where kept, Ash Wednesday, Holy Week, Ascension, Pentecost, Trinity, and the Sundays after Trinity or Pentecost), modeled as fixed dates, offsets from Easter, or a weekday relative to a fixed date.
- [ ] **P6.2** The fixed holy days each launch lectionary needs, as facts with citations, cross-checked against two independent sources with every difference listed (D20).
- [ ] **P6.3** Lectionary tables and expansion: civil-date tables, week-and-day tables keyed to the church year, proper lessons that override, transfers, alternatives, and optional lessons, all expanded into dated appointments (session, label, passages, the rule that produced them) for the catalog window. The reader can always see which rule produced today's readings.
- [ ] **P6.4 [RIGHTS] [REVIEW]** The 1979 Daily Office Lectionary: the two-year cycle (Year One from Advent before odd-numbered years, confirmed from the page), Morning and Evening readings, its psalms in the 1979 Psalter's numbering, and holy-day lessons. The source is the 1979 book itself, identified by printing; it is kept separate from the Sunday lectionary and the RCL. Agents bring it to `reviewed`; the owner's expert review is P10.9.
- [ ] **P6.5 [RIGHTS] [REVIEW]** The 1662 original Table of Lessons and its monthly Psalter, from an identified printing that carries the original table. The proper lessons for Sundays and holy days are included, and leap-year handling follows the book's own rule. It is labeled precisely and never confused with the 1871, 1922, or 1961 tables (Research finding 7). Territories follow D16, and the owner's expert review is P10.10.
- [ ] **P6.6** Golden files: complete outputs for 2026–2029 for each lectionary, with years that test year boundaries, Advent, early and late Easter (2008 on 23 March, 2038 on 25 April), leap days, and feast transfers. Each is cross-checked against two independent published sources (D20), with the differences listed and resolved.
- [ ] **P6.7** Write `docs/calendar-rules.md`: every rule, its source, its test, and every app convention.

## Phase 7: Hosting at daybyword.com

The site goes live early, marked as in development (D35). Agents provision
and deploy under D34's standing permission and its rules, and write every
script fresh, fitting the server's conventions (Research finding 14).

- [ ] **P7.1** Write `docs/deploy.md`: `/srv/www/daybyword.com` with `releases/`, `current`, `shared/storage`, and `shared/env` (secrets such as the VAPID private key, root-owned, mode 600); the system user `daybyword`; a free port (4316 unless the server says otherwise; check first); the pinned Swift toolchain through swiftly in a system location; the systemd unit with filesystem protections; the Caddy site in `/etc/caddy/sites/` with www redirecting permanently to the apex; security headers; logs; and rollback.
- [ ] **P7.2** `make deploy` (`deploy/deploy.sh`): over `ssh root@ubuntu-vm`, inside the shared deploy lock, fast-forward the server's clone; build a candidate as an unprivileged user from a clean `git archive` of `origin/main` with the pinned toolchain (a release build, plus the package and server tests on Linux); compile the catalog in release mode; install the release; run the server's migrations; boot-check on a spare port; switch `current`; restart; check `/up`; and restore the previous release on any failure. The checkout is never a web root.
- [ ] **P7.3** Provision the server as `docs/deploy.md` says (D34): record how the owner's other sites answer, archive `/etc/caddy`, add the user, directories, toolchain, environment file, unit, and Caddy site beside the existing ones without editing any other, and check the other sites again afterward.
- [ ] **P7.4** The first deploy (after P0.4), then check every name: daybyword.com serves over HTTPS, www redirects permanently with the path kept, and the headers are right. Confirm that the owner's other sites answer exactly as before.
- [ ] **P7.5** Backups: a nightly SQLite online backup of the server's databases, each copy checked and listed in a manifest (integrity, checksum, row counts, live commit), carried off the server age-encrypted through daybyword.com's own entry in `ubuntu-vm-backup` (D34), with a restore drill run once and written up. The catalog is rebuilt from the repository, not backed up.
- [ ] **P7.6** A post-deploy check (`make check-live`): status codes, redirects, TLS, security headers, secure cookies, and no requests to other hosts. `make deploy` runs it and prints only failures.
- [ ] **P7.7** Until launch (P18.5): `robots.txt` disallows crawling, every page carries `noindex`, and a quiet line says the site is in development.

## Phase 8: Today and the first plans

The brief's first release, starting with three plans that exercise the three
behaviors: discover, preview, start, read elsewhere, mark progress, receive
a reminder, and return after a missed day. Reliable reminders and quick
logging matter more than a long feature list. Everything here lands in the
app and on the web together (D37).

- [ ] **P8.1 [RIGHTS] [REVIEW]** The first three plans compiled and reviewed: **Gospels at your pace** (original; sequential), **the Bible in a year** (original; canonical order, balanced by reading time; pace or finish date), and the **1979 Daily Office Lectionary** (P6.4; calendar; "in review" until P10.9). Each has its full plan-page metadata.
- [ ] **P8.2** Starting a plan: a plain plan page with a sample week and workload; a start date, or "join today's readings" for calendar plans; the behavior, explained; reading days; sessions; how the reader reads (a physical Bible, YouVersion, or another app, with Copy reference); and a reminder offer. Notification permission is requested only after the reader chooses a reminder.
- [ ] **P8.3** Today: each active plan's next reading by session, with its label ("Gospels at your pace — Reading 12"), large references, **Open in …**, **Copy reference**, and **Mark read**. Calendar plans also show the tradition, edition, and rule that produced today's readings, with a link to the source. Rest days and finished sessions say so plainly, with no fanfare and no nagging.
- [ ] **P8.4** Marking: complete with one deliberate tap; mark part read (choose verses, or "part of it"); skip (labeled as a scheduling decision); log late for an earlier date; undo and redo. All of these are journal events.
- [ ] **P8.5** Opening a reading (D26): an adapter for YouVersion and Bible.com that builds the best link it can (the passage, or the chapter where that is the limit, said plainly) in the reader's chosen translation, opening the app where it is installed, and Copy reference everywhere. Test it on a device and record the date, app version, link format, and limits in `docs/destinations.md`.
- [ ] **P8.6** Physical Bible mode: references at the desk-glance size, a keep-the-screen-awake option, book and chapter called out for finding the place in print, and no link.
- [ ] **P8.7** The return flow over P5.8: a short welcome, the choices that apply with their previews, and a confirmation. History is never altered.
- [ ] **P8.8** iOS reminders over P5.12: local notifications in a rolling window; actions **Mark read**, **Snooze**, and **Open**; an option to hide passage details on the Lock Screen; quiet hours; a maximum per day; pending requests removed when a session is marked read; rescheduling on time-zone change. Turning reminders off never limits the app.
- [ ] **P8.9** A small and a Lock Screen widget showing the next reading, with an interactive **Mark read** (an App Intent writing to the shared journal through the App Group) and an obvious way to undo in the app.
- [ ] **P8.10** The web: browse and preview without saving anything; print a week's checklist without saving anything; start a plan with explicit consent to keep progress on daybyword.com in a browser profile (D10), then use Today and marking. A plain page explains what is stored and how to delete it.
- [ ] **P8.11** Offline: the app works fully in airplane mode. The web keeps Today and the coming week for the active plans, queues marks made offline with their event ids, and says clearly when it is offline.
- [ ] **P8.12** Progress, first version: assignments completed, recent reading days, and the next reading; a quiet welcome after returning from a gap.
- [ ] **P8.13** Settings, first version: reminders, the way to read and translation, book-name convention (D29), appearance, export of all personal data (JSON), delete all data, about, and version.
- [ ] **P8.14** Ship first light: an internal TestFlight build, and daybyword.com deployed with the three plans. This opens [GATE DEMO] (P0.7).

## Phase 9: Choosing a plan

- [ ] **P9.1** Onboarding: the short practical questions (what the reader hopes to read, realistic time, reading days, whether to follow a church calendar), tradition and Bible edition optional with "not sure", skippable at every step, and a search box from the first screen for readers who know their plan.
- [ ] **P9.2** Recommendations: three suitable plans from deterministic, documented, tested rules (never popularity, and never AI, D23), each with a concrete explanation tied to the reader's answers, a sample week, and the workload compared side by side, with the caveat that estimates are approximate.
- [ ] **P9.3** The catalog organized by goal (begin reading, the whole Bible, the New Testament, the Gospels, the Psalms, the church year, reading with a group), with filters for pace, length, reading days, morning and evening sessions, and books included.
- [ ] **P9.4** The plan page: exact title and edition, creator or source, a short explanation, whom it suits, a sample week, schedule kind, expected workload, completion or cycle length, coverage (whole Bible, selected books, or a recurring set, with repeats, optional passages, and omissions), the tradition and books included in neutral language, limitations beside advantages, the source note, the review level, and the permissions in plain words.
- [ ] **P9.5** The canon check before enrollment: when a plan appoints books the reader's Bible may not contain (D29), explain it before enrollment and offer an appropriate alternative or, where permissions allow, a clearly labeled adaptation. Original schedules are preserved.
- [ ] **P9.6** Plan comparison: two or three plans side by side (workload, coverage, length, behaviors, sessions).
- [ ] **P9.7** Search over plan metadata (FTS5).
- [ ] **P9.8** External directory entries (P4.7), clearly labeled, with a link out to the publisher.
- [ ] **P9.9** Public plan pages on the web as Day by Word's front door: clean URLs, honest titles and descriptions, structured data only where accurate, a sharing image from the owner's files (D19), and a sitemap.

## Phase 10: The launch catalog (parallel with Phases 9–17)

Each plan is compiled, checked against its claims (P4.4), reviewed
(`docs/editorial.md`), given complete plan-page metadata, and recorded in
`catalog/SOURCES.md`. Original plans are labeled as Day by Word's own.

- [ ] **P10.1 [REVIEW]** **Gospels at your pace** (from P8.1): the four Gospels, 89 chapters, in readings sized by reading time.
- [ ] **P10.2 [REVIEW]** **The Bible in a year**, canonical order, balanced by reading time without splitting chapters unless the plan says so; permits pace and finish-date behaviors.
- [ ] **P10.3 [REVIEW]** **The Bible in a year, five days a week**, with rest days intentional.
- [ ] **P10.4 [REVIEW]** **The New Testament in a year, five days a week**: its 260 chapters, one a day.
- [ ] **P10.5 [REVIEW]** **The Story of Scripture**: a short introduction to the biblical narrative in about 50 readings. Its selection involves editorial judgment, which the plan page explains.
- [ ] **P10.6 [REVIEW]** **A psalm a day**: 150 readings, with Psalm 119 in sections if workload calls for it; numbering per P3.8.
- [ ] **P10.7 [REVIEW]** **Proverbs through the month**: 31 readings by day of the month, with the 31st handled honestly in shorter months.
- [ ] **P10.8 [RIGHTS] [REVIEW]** **M'Cheyne's Calendar for Daily Readings** (1842): transcribed from an identified public-domain printing and proofread twice against its page images; four readings a day with M'Cheyne's own labels ("Family" and "Secret"); permits follow-the-calendar and at-my-pace behaviors; the source note gives the printing and pages.
- [ ] **P10.9 [OWNER] [RIGHTS] [REVIEW]** **The 1979 Daily Office Lectionary** (from P6.4): agents prepare a review packet (the source pages, the golden files, and the differences found); the owner reviews it as reviewer of record (D15); agents record the review and set `review: expert`.
- [ ] **P10.10 [OWNER] [RIGHTS] [REVIEW]** **The 1662 Table of Lessons and monthly Psalter** (from P6.5), reviewed the same way, with its territories set by D16.
- [ ] **P10.11 [REVIEW]** **Paul's letters**, in canonical order, with an optional arrangement in an order the plan page explains and labels as one view among several.
- [ ] **P10.12 [REVIEW]** **The deuterocanonical books** (for Bibles that include them): the books and additions each canon recognizes, labeled by canon in neutral words (D29).
- [ ] **P10.13** The catalog review: every launch plan at its required review level, every claim verified, every rights entry `cleared` for the territories served, and the criteria page current. Plans that are not ready wait; the catalog launches with what is ready.

## Phase 11: Progress and history

- [ ] **P11.1** The Progress screen: assignments completed, recent reading days (a plain week strip, never a heat map of performance), books explored, and the next reading.
- [ ] **P11.2** Quiet celebrations of returning after a gap, finishing a book, finishing a plan, and keeping a rhythm the reader chose: words, not confetti, and never a comparison with anyone else.
- [ ] **P11.3** The optional streak (D17): off by default, measured against the reader's reading days, small, and never mentioned in notifications.
- [ ] **P11.4** Coverage, shown once reference handling has proved dependable: unique verses read, by book, with the canon and counting method stated and partly read chapters shown as partial. Repeats never inflate it, and it is kept apart from plan completion.
- [ ] **P11.5** History: every assignment's state and every change, late logging, undo, and an archive of finished and paused plans.
- [ ] **P11.6** After finishing a plan: a few next plans chosen for the books the reader wants to explore, each with its reason.

## Phase 12: Widgets, notifications, and Apple integration

- [ ] **P12.1** The App Group and the capabilities the extensions need, registered through Xcode's automatic signing on the owner's account (D33).
- [ ] **P12.2** Widgets: small (the next reading), medium (today's sessions), large (this week's checklist), and Lock Screen accessories, each with interactive **Mark read** and the hide-passage option honored.
- [ ] **P12.3** StandBy, and a Control Center control for marking today's reading read.
- [ ] **P12.4** App Intents and App Shortcuts: "What's my reading today?", "Mark today's reading read", and "Open my plan", working with Siri, Spotlight, and the Action button.
- [ ] **P12.5** Notifications, finished: actionable, privacy-aware, grouped by plan, and Time Sensitive only if the reader chooses it.
- [ ] **P12.6** iPad: a sidebar layout, readable widths, and plan comparison side by side. Check that it runs on a Mac with Apple silicon as an iPad app.
- [ ] **P12.7** Spotlight indexing of plans in the catalog and the reader's own plans.
- [ ] **P12.8** Universal links: `apple-app-site-association` served by daybyword.com, so plan pages and shared links open in the app, with `webcredentials` for passkeys (P14.1).
- [ ] **P12.9** On-device diagnostics through MetricKit, kept on the device and included in support reports only when the reader chooses (no third-party crash reporting).

## Phase 13: Paper, print, and calendars

- [ ] **P13.1** The weekly printable checklist: a clean page through the web's print stylesheet and an iOS PDF through the share sheet, with checkboxes, references, the plan label, and the source note. Large print is an option, and plan permissions are respected (P4.5).
- [ ] **P13.2** The whole-plan printout, where permitted: the full schedule from a chosen start date and reading days, with the source note and required credit.
- [ ] **P13.3** A bookmark card: this month's readings sized to slip into a Bible, where permitted.
- [ ] **P13.4** Calendar export: an `.ics` file of upcoming readings (all-day or at the reminder time), and, for readers who sync, a private calendar subscription URL that is secret and revocable and updates as they read.
- [ ] **P13.5** Print and export tests: page breaks, large print, and permission enforcement.

## Phase 14: Accounts, backup, and sync

- [ ] **P14.1** Accounts with passkeys (D8): WebAuthn on the server (a decision entry records the library) and `AuthenticationServices` on iOS through associated domains, one-time recovery codes, opaque sessions stored hashed, minimal data, and rate-limited sign-in.
- [ ] **P14.2** The sync API (`/api/v1`): events since a cursor, idempotent uploads by event id, a JSON error envelope, rate limits, request-size limits, and authentication on every call.
- [ ] **P14.3** The iOS sync client in `ReadingData`: background refresh, retries with backoff, and a visible status ("Backed up 2 minutes ago", or "Backup unavailable offline").
- [ ] **P14.4** Joining histories: turning a web browser profile into an account, and adding the app's local history to an account, each previewed first, with no double counting.
- [ ] **P14.5** Export (JSON and CSV) and deletion everywhere: in-app account deletion that removes everything on the server, with backups expiring on their published schedule (D10).
- [ ] **P14.6** Sync tests: offline changes on two devices, retries, clock skew, interrupted uploads, accidental completions recovered, and the engine cases run over synced journals.
- [ ] **P14.7** Explicit consent, recorded: the separate statement shown before any reading data reaches the server, its record, and its withdrawal (D10, Research finding 11).
- [ ] **P14.8** Update the privacy policy and the App Store privacy label for accounts (P16.3, P16.7).

## Phase 15: The web app: install, offline, and reminders

- [ ] **P15.1** An installable web app: the manifest (name, icons from the owner's files, colors from the tokens), checked through Add to Home Screen on iPhone and installation on Android.
- [ ] **P15.2** Offline, finished: a service worker keeps the assets and the active plans' coming weeks, queues marks, and never caches another reader's data.
- [ ] **P15.3** Web push reminders: VAPID keys on the server only, schedules computed by `ReadingEngine`'s reminder rules, delivery by a scheduled job, and permission requested only when the reader sets a reminder. Notifications show the passage only if the reader allows it. A decision entry records any library. Confirm the platform facts of Research finding 10.
- [ ] **P15.4** Keyboard use throughout (with shortcuts listed on a `?` sheet, never overriding the browser's own), and sharing through the Web Share API with a copy-link fallback.
- [ ] **P15.5** Write `docs/browsers.md`: the support matrix (D30) and what was tested in each browser.
- [ ] **P15.6** Browser tests for every web flow at phone and desktop widths in Safari and Chrome, with Firefox and Edge checked by hand at each release.

## Phase 16: Public pages, legal, and App Store readiness

- [ ] **P16.1** The home page: what Day by Word is ("Find your plan. Read your Bible. Keep your place."), the plans actually in the catalog (never promised ones), the independence statement, and the way into Today.
- [ ] **P16.2** The support page (`/support`): support@daybyword.com, how to report a reading error (plan, assignment, and what is wrong), what is collected, and frequently asked questions.
- [ ] **P16.3 [OWNER]** The privacy policy and terms, drafted in `docs/legal/` from the real data flows: special-category data, consent, retention, backups, and deletion (D10). Recommend counsel review before any paid feature exists (Research finding 8). The owner approves them before they are published.
- [ ] **P16.4** The cookie statement: every cookie, what it holds, and why it is strictly necessary.
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
- [ ] **P17.6** Performance budgets in `docs/performance.md`: app launch to Today, the widget timeline, server time for Today and plan pages, and page weight, each measured and checked where measurable.
- [ ] **P17.7** Security: a strict CSP with no `unsafe-*`, rate limits on every form and API call, request-size limits, secure cookies, dependency updates reviewed for advisories, no secrets in the app binary, Keychain for tokens, and suitable file-protection classes.
- [ ] **P17.8** Pseudo-localization (long strings, right-to-left) to catch layout breakage before other languages arrive.
- [ ] **P17.9** Reminders, field-tested: a week of real reminders on a device across settings, with misses investigated.
- [ ] **P17.10** UI and browser tests for every critical flow in M2 and M3.
- [ ] **P17.11** A full review of every reader-facing string against AGENTS.md §3 (tone, neutrality, no guilt, no spiritual claims about records).

## Phase 18: Version 1.0 launch

- [ ] **P18.1** The rights audit: generate `docs/rights-audit.md` from `catalog/SOURCES.md`, with every served plan `cleared` for the territories it reaches (D16).
- [ ] **P18.2** Editorial sign-off: every [REVIEW] item at its level, with the owner's expert reviews of the prayer-book plans recorded (D15).
- [ ] **P18.3 [OWNER]** The beta (D36): a few weeks on external TestFlight (with Apple's beta review) and on the web, with readers the owner invites. Agents triage feedback into items and fix what it finds; feedback is anonymized before it enters the repository.
- [ ] **P18.4** Submit version 1.0 for App Review in the US storefront (D16), confirming with the owner first where the host requires it.
- [ ] **P18.5** Open daybyword.com to search engines (remove P7.7's notice, `noindex`, and the `robots.txt` block) and submit the sitemap, on release day.
- [ ] **P18.6 [OWNER]** Announce Day by Word where the owner chooses.
- [ ] **P18.7** Tag `v1.0.0` and record what shipped in the Handoff notes.
- [ ] **P18.8** Add other storefronts as each one's rights review completes (D16).
- [ ] **P18.9** The after-launch learning loop (D12, D25) in `docs/learning.md`: the support inbox routine, an opt-in survey linked from Settings, the aggregate data Apple provides, and a quarterly note on what readers are saying, folded into this plan as items.

## Phase 19: More ways to read

- [ ] **P19.1** Bible Gateway and ESV.org adapters, each with its translation choices, tested on a device and recorded in `docs/destinations.md` (D26).
- [ ] **P19.2** Olive Tree (its documented scheme), Logos (ref.ly), and Blue Letter Bible adapters, each tested the same way (Research finding 4).
- [ ] **P19.3** Audio: services that open a passage for listening, tested the same way, with the limit of each stated.
- [ ] **P19.4** A way for readers to ask for another app, through support mail, and a published list of what each adapter can and cannot open.
- [ ] **P19.5** Adapter tests: link formats, ranges, chapter fallbacks, and the copy-reference fallback for every destination.

## Phase 20: Companion plans and reading outside a plan

- [ ] **P20.1** A primary plan with a small companion plan (for example a psalm a day beside the Bible in a year), shown together on Today.
- [ ] **P20.2** Overlap detection between active plans through verse sets (P3.5): the reader may deliberately apply one reading to both. Repetition is never silently removed, because it may be intentional.
- [ ] **P20.3** Logging reading outside any plan, by reference, without forcing it into a schedule; it counts toward coverage, not toward any plan.
- [ ] **P20.4** Engine cases for every companion and off-plan rule.
- [ ] **P20.5** Companion suggestions on plan pages, with reasons.

## Phase 21: Groups, churches, and families (D24)

- [ ] **P21.1** Write `docs/groups.md`: what a group is, who sees what (individual completion and notes are never visible to leaders by default), moderation, abuse handling, and privacy.
- [ ] **P21.2** Church plans: a church publishes a permitted plan (a catalog plan, or its own after rights review) with a join link and a QR code.
- [ ] **P21.3** Joining: the group's current day, or the beginning where the plan allows, with the reader's own reminders and pace kept their own.
- [ ] **P21.4** Encouragement without surveillance: an optional group note from the leader, and a count of members only if the group chooses it. No rankings and no individual reports.
- [ ] **P21.5** A shared family schedule: one plan for a household, with each member's record kept private unless they share it.
- [ ] **P21.6** Leaving a group keeps the reader's own history.
- [ ] **P21.7** Report and block, published contact details, and an owner-only moderation view, as App Review expects for shared content.
- [ ] **P21.8 [GATE D11]** Church administration features, if D11 later makes them paid, designed only after churches have used the free version.

## Phase 22: Plan builder and private import

- [ ] **P22.1** The plan builder: choose books, reading days, and a duration or a pace, and get a schedule balanced by reading time, with a preview and the workload before saving. Private by default.
- [ ] **P22.2** Private import from a spreadsheet (CSV): a preview, with uncertain references flagged for correction before saving.
- [ ] **P22.3** Private import from a photograph of a printed schedule, using Apple's on-device text recognition (Vision) only, the exception D23 allows, with the same preview, and every reference confirmed by the reader.
- [ ] **P22.4** The rule, stated in the interface: private import does not authorize public redistribution.
- [ ] **P22.5** Catalog submissions: a way to propose a plan for the public catalog, with its source and rights evidence, reviewed under `docs/editorial.md` and `catalog/SOURCES.md`.
- [ ] **P22.6** Builder and import tests, including hostile and messy input.

## Phase 23: More traditions, canons, and languages [GATE DEMO]

Add each only when the editorial expertise and the rights are in place.
Psalm numbering, book names, canon, feast transfers, and calendar
conventions differ between traditions.

- [ ] **P23.1 [RIGHTS] [REVIEW]** The later English tables as separate plans: the 1871 Revised Table of Lessons, the 1922 alternative tables, and the 1961 revision, each labeled by edition.
- [ ] **P23.2 [RIGHTS] [REVIEW]** The Revised Common Lectionary, Sunday and festival readings, and its daily readings, by CCT permission (D38), with the Sunday and daily resources kept distinct.
- [ ] **P23.3 [RIGHTS] [REVIEW]** The 2019 ACNA Daily Office, only with Anglican House's written permission (D38).
- [ ] **P23.4 [RIGHTS] [REVIEW]** Common Worship and other Anglican provinces' lectionaries, each edition, calendar jurisdiction, and set of reuse terms verified.
- [ ] **P23.5 [RIGHTS] [REVIEW]** Catholic readings (the daily Mass lectionary and the Liturgy of the Hours) with a qualified reviewer and cleared rights.
- [ ] **P23.6 [RIGHTS] [REVIEW]** Orthodox daily Epistle and Gospel readings (both calendars), with a qualified reviewer, facts cross-checked under D20.
- [ ] **P23.7 [RIGHTS] [REVIEW]** A chronological plan, commissioned or licensed, with its approach labeled and never presented as the one correct order.
- [ ] **P23.8 [RIGHTS]** Partnership plans from ministries that grant permission (D38), hosted with their terms, or listed as external entries.
- [ ] **P23.9** Other languages, starting where readers ask (Spanish is likely first): interface strings, plan metadata, and book names in each language, with right-to-left support from P17.8.

## Phase 24: Apple Watch, Mac, and Android

- [ ] **P24.1** An Apple Watch app: the next reading, **Mark read**, a complication, and a Smart Stack widget, sharing `ReadingEngine`.
- [ ] **P24.2** The Mac: decide between the iPad app on Apple silicon and a native SwiftUI Mac target, based on readers' use.
- [ ] **P24.3 [GATE D6]** Android, after version 1.0: decide between a native Kotlin app and the Swift SDK for Android sharing `ReadingEngine`, record the decision, and build it with home-screen widgets and notification actions.
- [ ] **P24.4 [OWNER] [GATE D6]** A Google Play developer account (a payment in the owner's name), if P24.3 goes ahead.
- [ ] **P24.5 [GATE D6]** The engine's cases in Android's continuous integration, if P24.3 goes ahead.

## Phase 25: Sustainability (D11)

- [ ] **P25.1** Research the giving routes open to an individual (and to a nonprofit, if the owner forms one), including the current App Review rules for donations, and record the approach.
- [ ] **P25.2** A quiet "Support Day by Word" page: what gifts pay for (content review, rights administration, sync, notifications, support, accessibility, upkeep). It never appears on Today and never uses urgency.
- [ ] **P25.3 [OWNER]** Set up the giving route (accounts and payments in the owner's name).
- [ ] **P25.4 [GATE D11]** After launch, and only if readers show they value them, test paid extras against the supporter model, with clear terms and no lifetime price, keeping the free core whole.
- [ ] **P25.5** Church sponsorship of plans or features, if offered, credited plainly and never implying endorsement.

## Phase 26: Operations and annual maintenance

- [ ] **P26.1** Write `docs/operations.md`: the incident runbook, a quarterly backup-restore drill, log rotation, and the support inbox routine.
- [ ] **P26.2** Annual verification: each autumn, compare the coming year's computed lectionaries with published tables, fix discrepancies with tests, and extend the catalog window.
- [ ] **P26.3** A yearly platform upgrade after each September Xcode release (new SDK, deprecations, the deployment target), and Swift toolchain and Hummingbird updates as they come, with `make check` green.
- [ ] **P26.4** A yearly rights review: every permission's term, territories, and credit line still current, and every review date renewed.
- [ ] **P26.5** The errata routine: readers' reports checked against the source, fixed as a new plan version with a changelog (P4.6), and the reader thanked.
- [ ] **P26.6** Retention: idle web browser profiles expire on schedule with notice (D10), and backups expire as published.
- [ ] **P26.7 [OWNER]** Renew daybyword.com before **30 October** each year (Cloudflare; auto-renew recommended).
- [ ] **P26.8 [OWNER]** Renew the Apple Developer Program membership each year on its date.
- [ ] **P26.9** Watch the TLS certificates and the uptime of `/up` with a check the owner controls (no third-party tracking).

## Phase 27: Future directions

The owner decides priority, and promoted items become full phases. There is
never a built-in Bible reader (D13) or an AI feature (D23).

- [ ] **P27.1** Private notes and reflections: optional, on the device unless synced, and never shown to a group.
- [ ] **P27.2** Church-season collections (Advent, Lent, Easter) and seasonal plan suggestions.
- [ ] **P27.3** A public JSON feed of catalog metadata for churches' websites, if the owner wishes.
- [ ] **P27.4** Integrations with Bible apps that offer a supported way to report completion, only where verified (D26).
- [ ] **P27.5** visionOS and CarPlay audio, only if readers ask.
- [ ] **P27.6** Large-print and braille-friendly exports, made with the help of readers who use them.

---

## Handoff notes

*Replaced each session; keep under 25 lines. History lives in Git.*

- **2026-10-30 to 11-01:** P1.1–P1.11 and P1.13; P2.1, P2.2a, P2.3 (the owner
  chose Morning), the artwork batch, P2.4–P2.6. Stopped after P2.6 at the
  owner's request. **Next: P2.7** (iOS shell), then P2.8.
- **Waiting on the owner (P1.12):** xcodebuild cannot read the Xcode
  account's keychain credentials ("Failed to Use Accounts"), so re-sign in
  under Xcode → Settings → Accounts; create the App Store Connect record for
  `com.daybyword.app` (or allow it in a signed-in session); then install the
  first build from TestFlight. The app icon is now in place.
- **Needs a device:** P2.2b (hands-on use of competing apps).
- **Surprises:** Swift 6.4.2 had no official Docker image, and GitHub's
  runners cannot read swift.org's key file, so Linux uses our own verified
  installer with pinned keys (E21, E22). Xcode 27's simulator app is
  DeviceHub. Colima does not mount `/private/tmp`, so run `make test-linux`
  from the repository. The built-in browser refuses clipboard writes, so
  Copy reference's success path is unverified there (its fallback works).
  Tailscale SSH to `ubuntu-vm` asked for an interactive re-authentication on
  2026-10-30; Phase 7 will need the owner to approve it.
- **Design record:** the canvas
  (https://claude.ai/artifact/4YtusMm1DX7achVUPS67Lf, private) holds all three
  directions; Desk was only partly drawn when the owner chose. Morning's
  boards are in `design/mockups/`.
- **To confirm with the owner when convenient:** D34's note that agents may
  add daybyword.com's own entry to `ubuntu-vm-backup`.
