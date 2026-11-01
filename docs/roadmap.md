# Roadmap: the work after version 1.0

BUILD.md holds the plan to version 1.0. This file holds everything after
it: the phases planned from the start (19–27), and the work the owner moved
out of the 1.0 path on 2026-11-01 (D39), kept here with its original ids so
references such as "P6.4" in code, docs, and commits still resolve.

**When to read this file.** Only when BUILD.md's Phase 18 is finished, or
when an open item, a document, or a failing check points here. Agents do
not work items from this file before 1.0 unless the owner asks. When a
phase here becomes the next work, move it back into BUILD.md whole.

The markers mean what BUILD.md says they mean.

---

## Phase 6: Church calendars and lectionaries (after 1.0, D39)

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

## Phase 14: Accounts, backup, and sync (after 1.0, D39)

- [ ] **P14.1** Accounts with passkeys (D8): WebAuthn on the server (a decision entry records the library) and `AuthenticationServices` on iOS through associated domains, one-time recovery codes, opaque sessions stored hashed, minimal data, and rate-limited sign-in.
- [ ] **P14.2** The sync API (`/api/v1`): events since a cursor, idempotent uploads by event id, a JSON error envelope, rate limits, request-size limits, and authentication on every call.
- [ ] **P14.3** The iOS sync client in `ReadingData`: background refresh, retries with backoff, and a visible status ("Backed up 2 minutes ago", or "Backup unavailable offline").
- [ ] **P14.4** Joining histories: turning a web browser profile into an account, and adding the app's local history to an account, each previewed first, with no double counting.
- [ ] **P14.5** Export (JSON and CSV) and deletion everywhere: in-app account deletion that removes everything on the server, with backups expiring on their published schedule (D10).
- [ ] **P14.6** Sync tests: offline changes on two devices, retries, clock skew, interrupted uploads, accidental completions recovered, and the engine cases run over synced journals.
- [ ] **P14.7** Explicit consent, recorded: the separate statement shown before any reading data reaches the server, its record, and its withdrawal (D10, Research finding 11).
- [ ] **P14.8** Update the privacy policy and the App Store privacy label for accounts (P16.3, P16.7).

## Phase 28: Moved out of the 1.0 path (D39)

Moved from BUILD.md on 2026-11-01 under D39. Each item keeps its id and
wording; the new items (P28.n) are the parts of rewritten 1.0 items that
were left for later.

### Scripture and the catalog

- [ ] **P3.1b** The Greek Orthodox canon and order, with 1 Esdras, 3 Maccabees, the Prayer of Manasseh, and Psalm 151 (and 4 Maccabees as an appendix, if the sources agree). Needs a primary source (a Church of Greece edition's contents) and a second independent one, since secondary sources differ on 4 Maccabees and the Prayer of Manasseh. Douay "1 Esdras" is Ezra, so 1 Esdras needs its Douay name in the same change (the Douay appendix titles it "The Third Booke of Esdras"); the registry refuses the clash.
  - *Note (agent, 2026-11-01):* no Church of Greece (Apostoliki Diakonia) contents page was found online; Greek sites reproducing its text (for example saint.gr) mark 4 Maccabees "Παράρτημα" but state no edition. Next try: a scan of an Apostoliki Diakonia Old Testament, or a library record of its contents.
- [ ] **P3.2b [RIGHTS]** Hebrew, Greek, and Latin schemes mapped from TVTMS's expanded data, with the mapping rules and every change to the data recorded in `docs/scripture.md` as its licence asks, and the credit carried to the sources page (P16.5).
- [ ] **P3.8** Psalm numbering: map Hebrew numbering to Greek and Latin, display both wherever a plan uses the numbering the reader's Bible does not, and add tests for every psalm that differs.
- [ ] **P4.5** The rights guard: each plan's permitted uses (catalog listing, full schedule in the app, offline, print and export, adaptation, territories, commercial use) are compiled into the catalog, and the app and the server enforce them. For example, printing is unavailable where export is not permitted, and an adaptation is unavailable where adaptation is not.
- [ ] **P4.7** External directory entries: a plan described with its publisher's link and no schedule, labeled as an outside plan so it never looks hosted.
- [ ] **P28.1** References from other sources' citation styles: a forgiving parser drawn from the real styles of historic plans and lectionaries (for example "Isa 40:1-11", "Luke 2:1-14(15-20)", "Ecclus 44:1-15", "1 Kgs 19", "Song 2"), reading book names under one naming convention at a time (E27), with at least 2,000 cases. *(The part of P3.4 moved by D39; 1.0 plans use the strict format.)*
- [ ] **P28.2** The fuller reference model: partial verses (`a` and `b`), optional verses, alternatives ("either … or …"), and the source's own displayed wording. *(The part of P3.3 moved by D39.)*
- [ ] **P28.3** Plan versions in full: changelogs that explain material corrections, original appointments kept available, assignment ids kept stable or mapped, and a preview before an enrollment moves to a new version, checked by the compiler. *(The part of P4.6 moved by D39; needed with the first correction after release.)*

### The engine

- [ ] **P5.9** Sessions and multi-reading days: morning and evening (and M'Cheyne's "Family" and "Secret" readings), each with its own state; a day is complete only when its sessions are.
- [ ] **P5.13** Performance: today's view for ten enrollments over five years of events computes within a measured budget on a phone (start at 20 ms) and on the server, recorded in `docs/performance.md`.
- [ ] **P28.4** Follow the calendar for church-year schedules: today's appointment from tables compiled by Phase 6, with the rule that produced it shown, and a labeled personal adaptation where a plan permits one. *(The part of P5.7 moved by D39.)*

### Hosting

- [ ] **P7.5** Backups: a nightly SQLite online backup of the server's databases, each copy checked and listed in a manifest (integrity, checksum, row counts, live commit), carried off the server age-encrypted through daybyword.com's own entry in `ubuntu-vm-backup` (D34), with a restore drill run once and written up. The catalog is rebuilt from the repository, not backed up.

### Plans, choosing, and the launch catalog

- [ ] **P8.15 [GATE DEMO]** Draft the four letters of D38 in `docs/owner-drafts/`, each describing the app, the exact use, the attribution, and the demo, generic enough to sit in a public repository (D4). *(Formerly P0.7; moved here at the owner's request, 2026-11-01.)*
- [ ] **P8.16 [OWNER] [GATE DEMO]** The owner confirms each letter. Agents send it from the owner's address, or the owner sends it, and agents record each response's status in `catalog/SOURCES.md`. The letters themselves stay off the repository. *(Formerly P0.8; moved here at the owner's request, 2026-11-01.)*
- [ ] **P9.5** The canon check before enrollment: when a plan appoints books the reader's Bible may not contain (D29), explain it before enrollment and offer an appropriate alternative or, where permissions allow, a clearly labeled adaptation. Original schedules are preserved.
- [ ] **P9.6** Plan comparison: two or three plans side by side (workload, coverage, length, behaviors, sessions).
- [ ] **P9.7** Search over plan metadata (FTS5).
- [ ] **P9.8** External directory entries (P4.7), clearly labeled, with a link out to the publisher.
- [ ] **P9.10** A hands-on competitive teardown on a device: onboarding, missed-day behavior in practice (YouVersion's "Catch Me Up", Sola's rescheduling, ReadingPlan's pace), links out, widgets, and reminders, recorded in `docs/research/competitors.md`, confirming the remaining † rows of the feature map. Needs a session with an iPhone that may have these apps installed; do it before settling P9.1–P9.6. *(Formerly P2.2b; moved here at the owner's request, 2026-11-01.)*
- [ ] **P10.8 [RIGHTS] [REVIEW]** **M'Cheyne's Calendar for Daily Readings** (1842): transcribed from an identified public-domain printing and proofread twice against its page images; four readings a day with M'Cheyne's own labels ("Family" and "Secret"); permits follow-the-calendar and at-my-pace behaviors; the source note gives the printing and pages.
- [ ] **P10.9 [OWNER] [RIGHTS] [REVIEW]** **The 1979 Daily Office Lectionary** (from P6.4): agents prepare a review packet (the source pages, the golden files, and the differences found); the owner reviews it as reviewer of record (D15); agents record the review and set `review: expert`.
- [ ] **P10.10 [OWNER] [RIGHTS] [REVIEW]** **The 1662 Table of Lessons and monthly Psalter** (from P6.5), reviewed the same way, with its territories set by D16.
- [ ] **P10.12 [REVIEW]** **The deuterocanonical books** (for Bibles that include them): the books and additions each canon recognizes, labeled by canon in neutral words (D29).
  - *Note (agent, 2026-11-01):* word counts cover the 66 books only (P3.6). This plan needs counts for the deuterocanonical books too; the WEB numbers Greek Esther, Daniel, and Sirach 33 differently from the English scheme, so map them as `scripts/wordcounts.swift` maps Romans.
- [ ] **P11.6** After finishing a plan: a few next plans chosen for the books the reader wants to explore, each with its reason.
- [ ] **P28.5** Catalog filters (pace, length, reading days, sessions, books included), once the catalog is large enough to need them. *(The part of P9.3 moved by D39.)*

### Apple integration, print, and the web

- [ ] **P12.3** StandBy, and a Control Center control for marking today's reading read.
- [ ] **P12.5** Notifications, finished: actionable, privacy-aware, grouped by plan, and Time Sensitive only if the reader chooses it.
- [ ] **P12.7** Spotlight indexing of plans in the catalog and the reader's own plans.
- [ ] **P12.8** Universal links: `apple-app-site-association` served by daybyword.com, so plan pages and shared links open in the app, with `webcredentials` for passkeys (P14.1).
- [ ] **P12.9** On-device diagnostics through MetricKit, kept on the device and included in support reports only when the reader chooses (no third-party crash reporting).
- [ ] **P13.2** The whole-plan printout, where permitted: the full schedule from a chosen start date and reading days, with the source note and required credit.
- [ ] **P13.3** A bookmark card: this month's readings sized to slip into a Bible, where permitted.
- [ ] **P15.3** Web push reminders: VAPID keys on the server only, schedules computed by `ReadingEngine`'s reminder rules, delivery by a scheduled job, and permission requested only when the reader sets a reminder. Notifications show the passage only if the reader allows it. A decision entry records any library. Confirm the platform facts of Research finding 10.
- [ ] **P17.6** Performance budgets in `docs/performance.md`: app launch to Today, the widget timeline, server time for Today and plan pages, and page weight, each measured and checked where measurable.
- [ ] **P17.8** Pseudo-localization (long strings, right-to-left) to catch layout breakage before other languages arrive.
- [ ] **P28.6** The large widget (this week's checklist). *(The part of P12.2 moved by D39.)*
- [ ] **P28.7** A private calendar subscription URL, secret and revocable, that updates as the reader reads, for readers who sync. *(The part of P13.4 moved by D39; it needs Phase 14.)*
- [ ] **P28.8** Web progress kept on daybyword.com in a browser profile after explicit, separate consent (D10), as a step towards accounts. *(The part of P8.10 moved by D39; at 1.0 the web keeps progress in the reader's browser.)*

---

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
