# Engineering decisions

A numbered, append-only log of engineering decisions for Day by Word. Product
decisions are the owner's and live in BUILD.md's Owner decisions table
(D1–D39); this file records how they are carried out and why.

**How to use this file.** Add a new entry at the end with the next number,
the date, who decided (`agent` or `owner`), the decision, and the reasons.
Never edit or delete an old entry's decision. To change one, add a new entry
that supersedes it, and add a single line under the old entry pointing to
the new one (*Superseded by E12*). Every third-party package needs an entry
here before it is added (AGENTS.md §5).

Entries E1–E17 were recorded together on 2026-10-30, seeded from BUILD.md's
Engineering foundations and the owner's decisions.

---

### E1. One repository, one gate

*2026-10-30, owner (Engineering foundation 1).* The app, the server, the
Swift packages, the catalog, and the tests live in one repository, and
`make check` runs every check. Nothing is ticked in BUILD.md unless it
passes.

**Why:** one gate keeps the app and the web from drifting (D37), and a single
command is something every session can run before every commit.

*Superseded in part by E29: `make check` is the per-commit gate, and `make check-full` runs everything.*

### E2. The plan, the enrollment, and the record are separate

*2026-10-30, owner (Engineering foundation 2).* A *plan version* holds its
edition, permissions, references, and calendar rules, and is immutable once
published. An *enrollment* holds a reader's start, behavior, reading days,
sessions, reminders, way of reading, and the plan version it follows. The
*journal* holds what the reader actually did and when.

**Why:** changing a schedule must never rewrite a plan or erase a record.
Keeping the three apart makes that a property of the data model rather than
a rule every feature has to remember.

### E3. An append-only event journal

*2026-10-30, owner (Engineering foundation 3).* Reading records are
append-only events (completed, partly completed, skipped, undone, logged
late, enrollment changed, catch-up applied, calendar rejoined), each with a
UUIDv7 id, the civil date it concerns, the instant and time zone it
happened, and its device. State is a deterministic fold over the events, and
undo is an event too. Sync exchanges events idempotently. Only a reader's
own deletion request removes events.

**Why:** an event history is honest by construction (nothing is silently
rewritten), makes undo and late logging ordinary, and lets sync merge two
devices' offline marks without double counting: the same event id applied
twice is a no-op, and the fold gives the same answer in any arrival order.

### E4. One engine, everywhere

*2026-10-30, owner (Engineering foundation 4, D5).* `ReadingEngine`, a Swift
package that uses Foundation only, is the single implementation of
references, schedules, progress, and reminder rules. The app, its widgets
and other extensions, the server, and the catalog compiler all use it.
`docs/engine.md` specifies it and table-driven cases pin it. Its tests run on
macOS and on Linux. No app view, server route, JavaScript module, or SQL
query reimplements engine logic; the web's JavaScript asks the server.

**Why:** two implementations of the same rules drift, and a reader who sees
one answer on the phone and another on the web stops trusting both.

### E5. Calendars are computed once, at compile time

*2026-10-30, owner (Engineering foundation 5).* The catalog compiler
evaluates every church-year and lectionary rule and writes dated
appointments into the catalog for a window of years (2020–2045 at first).
The engine only looks appointments up by date.

**Why:** the hardest rules (the computus, transfers, proper lessons) then
live in one place with golden tests, and the app, the widgets, and the
server never have to agree on a calendar computation at run time.

### E6. A compiled, versioned catalog

*2026-10-30, owner (Engineering foundation 6).* `catalog/` (plain-text plans,
rule tables, scripture data, and `SOURCES.md`) compiles into a deterministic
`Catalog.sqlite` with a schema version and a checksum. It is bundled in the
app, opened read-only by the server, and later delivered to the app as a
signed update. The compiler refuses unverified references, false coverage
claims, and uncleared sources.

**Why:** a compile step is where references are verified, claims are
computed, and rights are enforced, before anything reaches a reader. A
read-only artifact cannot be edited in production by accident.

### E7. Civil dates, not instants

*2026-10-30, owner (Engineering foundation 7).* Plans and enrollments speak
in `CivilDate` (year, month, day), never a Foundation `Date` standing for a
day. The reader's "today" is resolved once, at the edge, from their device's
time zone. Reminders are wall-clock times with an IANA time zone.

**Why:** a `Date` is an instant, and an instant is a different day in
different places. Treating a day as an instant is the classic source of
off-by-one-day bugs around midnight, daylight saving time, and travel.

### E8. Local-first app, server-backed web

*2026-10-30, owner (Engineering foundation 8, D8, D10).* The app works fully
offline without an account. The web keeps progress on the server only with
consent, caches the active plans for offline reading, and queues marks made
offline.

**Why:** reading happens at six in the morning with a paper Bible, often
without a signal, and reading data can reveal religious belief, so it stays
on the device unless the reader chooses otherwise.

*Superseded in part by E29: at 1.0 the web keeps progress in the browser (D39).*

### E9. SQLite everywhere

*2026-10-30, owner (Engineering foundation 9, D5).* The system `SQLite3`
library is used through `ReadingData`'s own small wrapper on iOS and on
Linux, for the catalog, the app's journal, and the server's databases. WAL
mode is used on the server, with migrations versioned in code.

**Why:** one storage engine on every platform, no database server to run,
simple backups (the online backup API), and no third-party driver.

### E10. Few dependencies

*2026-10-30, owner (Engineering foundation 10).* The Apple app has zero
third-party runtime dependencies; its approved build tools are XcodeGen and
Apple's `swift format`. The server depends on Hummingbird 2 and the Swift
Server Work Group packages it brings (SwiftNIO, swift-log, Service
Lifecycle, HTTP Types). Every other package needs an entry in this file
first, and every package is pinned in `Package.resolved`. The web's
JavaScript is the project's own vanilla ES modules, with no npm, no bundler,
and no third-party scripts.

**Why:** every dependency is code that can change under us, phone home, or be
abandoned. A small project maintained by agents across many sessions is
easier to keep correct when nearly everything is its own.

### E11. Modern browsers, server-rendered pages, a strict CSP

*2026-10-30, owner (Engineering foundation 11, D30).* The server renders
semantic HTML, and the project's own JavaScript adds the web app's
interactivity. The targets are the current and previous major versions of
Safari, Chrome, Firefox, and Edge; older browsers get a plain notice. A
strict Content Security Policy allows nothing from other hosts.

**Why:** server rendering keeps public plan pages findable and fast;
targeting only modern browsers keeps the JavaScript small and dependency-free;
and a strict CSP makes "nothing loads from elsewhere" a property the browser
enforces.

### E12. Shared design tokens

*2026-10-30, owner (Engineering foundation 12).* `design/tokens.json`
generates both the Swift color assets and the web's `tokens.css`, and tests
check contrast and ban raw colors.

**Why:** the app and the web must look like one product (D37), and contrast
is checked once, at the source.

### E13. Our own simple formats

*2026-10-30, owner (Engineering foundation 13).* Plans use `key: value`
front matter and a tab-separated schedule; rule tables are JSON; our code
parses them.

**Why:** plain text is easy to review line by line against a source page, and
a format we parse ourselves needs no dependency.

### E14. A date override for tests

*2026-10-30, owner (Engineering foundation 14); the last sentence is the
agent's.* Debug builds accept `-today YYYY-MM-DD`, and the development
server accepts `?today=YYYY-MM-DD`, so tests and screenshots can pin any
day. Release builds and the production server ignore both.

**Why:** schedules depend on the date, and a test that depends on the real
date is a test that fails next month.

### E15. Internationalized from the start

*2026-10-30, owner (Engineering foundation 15).* Every interface string goes
through a String Catalog on Apple platforms and the server's string tables
on the web, English first.

**Why:** retrofitting localization means touching every screen; doing it from
the first screen costs almost nothing.

### E16. Swift on the server: Hummingbird 2 and SQLite

*2026-10-30, owner (D5).* The web is served by a Swift server built on
Hummingbird 2, with SQLite, sharing `ReadingEngine` and `ReadingData` with
the app.

**Why:** the owner chose one language. The alternative recommended at the
time was a Rails site with a second engine in Ruby, which would have meant
every reading rule written twice and kept in agreement forever. D5 records
the owner's choices of Hummingbird 2 over Vapor 4 and of SQLite over
PostgreSQL without further reasons. The evidence at the time supports both
(the agent's reading): Hummingbird 2 is a rewrite on structured concurrency
with few dependencies, and Vapor's next major version plans to build on
Hummingbird's server (Research finding 12); and the data is small, the
server is one machine, and the same SQLite library already serves the app.

### E17. No tracking of any kind

*2026-10-30, owner (D12, D23, AGENTS.md §3 and §5); the list of logged
fields is the agent's.* No analytics,
advertising, tracking, crash-reporting, session-replay, affiliate,
remote-font, or CDN code; no SDK that phones home; no AI model or service.
Server logs record request metadata only (method, route pattern, status,
duration) and never passages, plans, reading events, or personal data. No
personal data goes in a URL; the one exception is the secret, revocable
calendar-feed token, which is a credential and is handled as one.

**Why:** reading history and tradition preferences are sensitive, and in some
laws special-category data (Research finding 11). The surest way to protect
data is not to collect it, and the surest way not to collect it is to have
no code that could.

### E18. ReadingData's SQLite wrapper

*2026-10-30, agent.* `ReadingData` talks to SQLite through its own small
wrapper over the C API: a `Database` class (one connection, opened read-only,
read-write, or create), `execute` for parameterless statements such as
schemas, `run` and `query` for one statement with positional parameters
bound as `SQLiteValue`s, and `transaction` that commits or rolls back. Rows
come back as `SQLiteRow` values (column names and values). On Apple
platforms it imports the SDK's `SQLite3` module; on Linux a system-library
target, `CSQLite`, maps `<sqlite3.h>` and links `libsqlite3` (from
`libsqlite3-dev`).

**Why:** E9 and E10 call for the system library and no third-party driver.
The C API is small, and a wrapper of about two hundred lines covers what the
catalog, the journal, and the server's stores need. Parameters are always
bound, never interpolated into SQL. A connection is not `Sendable`: code
that shares one across tasks owns it inside an actor, which keeps SQLite's
threading rules out of every caller. Typed row decoding, migrations, and
the backup API are added to this wrapper when an item needs them.

### E19. Server-rendered HTML through the project's own `HTML` type

*2026-10-30, agent.* The server writes its pages with a small `HTML` type of
its own (`Server/Sources/DayByWordWeb/HTML.swift`): markup is written as
Swift string literals, and every interpolated `String` is escaped unless it
is itself `HTML`. Numbers interpolate as digits; any other type does not
interpolate at all, so it has to be turned into text or markup on purpose.
Pages are plain Swift functions that return `HTML`.

**Why:** the options were the Hummingbird project's Mustache library, a
third-party Swift HTML DSL, or our own type. Our own type needs no
dependency (E10) and is about a hundred lines. Templates are checked by the
compiler, so a renamed value or a missing partial is a build error rather
than a blank on a reader's page, and there are no template files to find at
run time on the server. Escaping is the default and the type system
enforces it, which matters because plan titles and readers' input reach
these pages. Mustache's logic-less templates would push the same logic into
view models anyway, and nobody edits these templates but agents writing
Swift. If the pages outgrow string literals, a result-builder DSL of our own
can replace them behind the same functions.

### E20. The server's packages

*2026-10-30, agent.* `Server/Package.swift` depends directly on:

| Package | Version | Use |
|---|---|---|
| `hummingbird-project/hummingbird` | 2.28.0 (up to next minor) | the HTTP server, router, middleware, and file serving (D5); its `HummingbirdTesting` library in tests only |
| `apple/swift-http-types` | 1.8.0 (up to next minor) | `HTTPField` names for security headers |
| `apple/swift-log` | 1.16.2 (up to next minor) | structured logging |

Everything else in `Server/Package.resolved` comes in through Hummingbird:
SwiftNIO and its extras, HTTP/2, and SSL; Service Lifecycle; swift-metrics,
swift-distributed-tracing, and swift-service-context; swift-configuration;
swift-collections, swift-algorithms, swift-async-algorithms, swift-atomics,
swift-numerics, and swift-system; and, for `HummingbirdTesting` only,
AsyncHTTPClient with swift-crypto, swift-certificates, and swift-asn1. These
are Apple and Swift Server Work Group packages (E10).

**Why:** Hummingbird 2.28.0 was the newest release on 2026-10-30. The two
direct additions are already part of Hummingbird's graph, so naming them
adds no code; it only makes the imports explicit. Versions are held by
`Package.resolved`, which is committed, and deploys build with
`--force-resolved-versions` so the server builds exactly what was tested.
Updates are deliberate (BUILD.md P26.3).

### E21. The pinned toolchain on Linux comes from swiftly

*2026-10-30, agent.* `.swift-version` pins the Swift toolchain (6.4.2 at
first). On this Mac it is the toolchain inside Xcode, and
`scripts/check-toolchain.sh` (run by `make check`) fails if `swift` reports
another version. On Linux, everywhere, the toolchain is installed by
swiftly from `.swift-version`: in the container that `make test-linux`
builds (`scripts/linux/Dockerfile`: Ubuntu 24.04, swiftly verified against
swift.org's signing keys, then `swiftly install` of the pinned version and
its system packages), in the CI Linux job, which runs `make test-linux`, and
on the server (P7.1).

**Why:** BUILD.md P1.6 first said "the official Swift container", but Swift
6.4.2 was released on 2026-10-29 and on 2026-10-30 Docker Hub's official
`swift` image offered only 6.4.1, so pinning to the official image would
have meant a different compiler on Linux than on this Mac. swiftly is what
the server uses anyway (D27, P7.1), reads `.swift-version` itself, and
verifies each toolchain's signature, so one mechanism gives the same
compiler in the container, in CI, and in production. The image is cached
locally by version (`daybyword-linux:<version>`), and build products live in
a named volume, so later runs take seconds. The repository is mounted
read-only, so a Linux run can never change the checkout.

*Superseded by E22.*

### E22. The pinned toolchain on Linux comes from our own verified installer

*2026-11-01, agent; supersedes E21's use of swiftly.* On Linux everywhere (the
`make test-linux` container, the CI Linux job, and the server),
`scripts/linux/install-swift.sh <version> <prefix>` downloads the Ubuntu
24.04 toolchain for `.swift-version` from download.swift.org, checks its
detached signature with gpg against swift.org's public signing keys kept in
`scripts/linux/swift-signing-keys.asc`, and unpacks it to
`<prefix>/<version>`. The Dockerfile installs the toolchain's system
packages from swift.org's list for Ubuntu 24.04.

**Why:** swiftly always re-downloads the signing keys from
`www.swift.org/keys/all-keys.asc` before verifying, and from GitHub's hosted
runners that address returned no valid OpenPGP data (CI runs 41051782933
and 41053281128), so neither swiftly nor a key download could work in CI.
Keeping the public keys in the repository, fetched once on 2026-10-30 from
swift.org (fingerprints include Swift 6.x Release Signing Key
`52BB 7E3D E28A 71BE 22EC 05FF EF80 A866 B47A 981F` and Swift Automatic
Signing Key #4 `E813 C892 820A 6FA1 3755 B268 F167 DF1A CF9C E069`), is
stricter than fetching them on every run, and the same thirty-line script
serves the container, CI, and the server. If swift.org rotates its keys,
refresh the file and record the new fingerprints here.

### E23. Design tokens generated by a Swift script

*2026-11-01, agent.* `scripts/tokens.swift` (run by `make tokens`) reads
`design/tokens.json` and writes the app's `apple/Shared/Colors.xcassets`
(one color set per token with light and dark values, plus `AccentColor`),
`apple/Shared/DesignTokens.swift` (`Palette`, `Radius`, `Spacing`, and
`TypeScale`), and the web's `Server/Public/assets/tokens.css` (custom
properties, with dark values under `prefers-color-scheme` and a
`data-theme` override for the reader's own choice). `make check` runs its
`check` mode, which fails if an output is stale or if any text pair in
`docs/design.md`'s table is below WCAG AA (or its stated ratio is wrong), and
`scripts/check-colors.sh`, which fails on any raw color in the app's Swift,
the server's HTML, or a stylesheet. Xcode's own asset-symbol generation is
off, so `Palette` is the only way to name a color. Type sizes scale with
Dynamic Type through `@ScaledMetric` relative to a text style
(`apple/Shared/Typography.swift`) and in `rem` on the web.

**Why:** one source of truth for both platforms (E12) with no dependency, in
the project's own language; a script rather than a package because it runs
only at development time. Generated files are committed so the app and the
server build without running it.

### E24. The app's shell: routes, and restoring the reader's place

*2026-11-01, agent.* The app's three sections are a SwiftUI `TabView`, each
tab with its own `NavigationStack` bound to a path of `Destination` values,
and Settings is a sheet opened from a toolbar button on each tab's root
(`apple/App/Navigation/`). Every place the app can be sent is an `AppRoute`,
read from a `daybyword://` link or from an https link on daybyword.com
whose path is the same, so the app and the web share one set of addresses
(docs/urls.md, P2.9). A link the app does not understand changes nothing.
The selected tab and the three paths are encoded as JSON in `@SceneStorage`.

**Why scene storage:** docs/product.md asks for both "opens to Today" and
"remembers the place within each tab". Scene storage gives exactly that
split. When the system ends the app in the background and relaunches it,
the reader returns to the same tab and page, because they never chose to
leave. When the reader closes the app themselves (swiping it away), the
scene's state is discarded and the next launch opens on Today. Nothing
about where the reader was is written to the app's own database, so
navigation never becomes reading data. Data saved by an older version that
cannot be decoded is ignored, and the reader starts on Today.

### E25. Interface strings: one String Catalog and a typed web table

*2026-11-01, agent.* The app and the widget share one String Catalog,
`apple/Shared/Localizable.xcstrings`, compiled into both bundles. English
keys are the English text, as SwiftUI writes them. `scripts/strings.swift`
reads the `.stringsdata` files Xcode emits when it builds (`make strings`
adds new keys and drops stale ones; `make check` fails on a missing or stale
key, and on words passed to `Text(verbatim:)`, which skips localization;
the debug component gallery's sample content is exempt). On the web,
`StringKey` names every interface string and `Strings.english` holds its
text, with `{name}` placeholders; pages and components ask `text(_:)` for
a key. Server tests check that every key has English and that every word a
page shows, including titles, labels, and the copy button's messages, comes
from the table.

**Why:** E15 asks for localization from the first screen. Xcode's own
catalog sync runs only in the IDE, so a script keeps the catalog honest in
`make check` and in CI. On the server, a Swift table needs no resource
bundle (which differs between macOS and Linux) and turns a misspelled key
into a compile error. Until a second language exists, `text(_:)` always
answers in English; the reader's language will then come from the request.

### E26. Tours: an XCUITest and our own WebDriver client

*2026-11-01, agent.* The app tour is an XCUITest (`TourTests`) that launches
the app with the reader's appearance set to light and then dark, visits
Today, Plans, Progress, a plan, a week, and Settings, attaches a screenshot
of each to the result, and saves it as a PNG when the test runner gets
`DBW_SCREENSHOTS` (`make tour-app` writes to `screenshots/app/`). The web
tour is `scripts/webtour.swift`: it starts the server on a spare port,
drives a browser through the W3C WebDriver protocol with a few commands of
its own over `URLSession`, visits every address in docs/urls.md at 1280 px
and 500 px wide in light and dark, checks the heading, the single
current-section marker, the theme, sideways scrolling, the hidden browser
notice, the footer, and the skip link's place, saves screenshots to
`screenshots/web/`, and checks that a Settings choice applies and is kept.
`make check` runs the web tour; the app tour runs with `make test-ui` and
`make tour-app`.

The browser is **Firefox through geckodriver** by default, and Safari
through `safaridriver` with `DBW_WEBDRIVER=safari`. Safari needs "Allow
remote automation" turned on in its Developer settings, which is the
owner's setting to change; Firefox needs nothing turned on, and GitHub's
macOS images carry both it and geckodriver. Firefox will not make a window
narrower than 500 px, so phone widths (375 and 320 px) are still checked by
hand in a browser's device emulation.

**Why:** the project has no npm (AGENTS.md §5), and the WebDriver commands a
tour needs are a page of Swift. No package or driver library is added.
Screenshots are gitignored and never committed.

*Superseded in part by E29: the web tour runs in `make check-full`, not `make check`.*

### E27. The book registry: USFM ids, canons with orders, and names by convention

*2026-11-01, agent.* `catalog/scripture/books.json` registers every book the
catalog may name, read and checked by `BookRegistry` in `ReadingEngine`; the
catalog compiler refuses to build while it has a problem.

- **Ids are USFM 3.0 book codes** (`BookID`). A book that some Bibles print
  inside another and others print apart has its own id: the Greek additions
  to Esther (`ESG`), the Letter of Jeremiah (`LJE`), and Daniel's additions
  (`S3Y`, `SUS`, `BEL`). In Day by Word `ESG` means the additions printed
  apart, as the King James Bible prints them, whatever USFM's wider use.
- **A canon is a set of books with one or more printed orders**, and each
  order cites its sources. Every order of a canon lists the same books, Old
  Testament before New. A canon's `includes` says which listed book holds
  material other Bibles print apart (the Catholic canon's `DAN` holds `S3Y`,
  `SUS`, and `BEL`; `EST` holds `ESG`; `BAR` holds `LJE`), so a plan can be
  checked against a reader's canon whichever way its Bible prints them. The
  chapter and verse numbers of those forms belong to versification (P3.2).
- **Two Catholic orders**: the New American Bible, Revised Edition puts 1 and
  2 Maccabees after Esther, and the Nova Vulgata and the Douay-Rheims put them
  after Malachi. The sources disagree because the printings do, so both are
  registered rather than one chosen as "the" Catholic order.
- **Names by convention** (D29): every book has a common English name and
  SBL abbreviation; the King James and Douay-Rheims conventions give only
  the names that differ, each rule written in the file. A convention's
  abbreviation is given only where the SBL Handbook lists that name, and
  otherwise the full name is shown, so no abbreviation is invented. Names
  and abbreviations are unique within each convention, which the registry
  checks.
- **The same name can mean different books under different conventions**:
  Douay "1 Kings" is common "1 Samuel", and Douay "1 Esdras" is Ezra, not the
  book USFM calls 1 Esdras. The reference parser (P3.4) must therefore read
  names under the convention a source uses, never across all of them at once.

**Why:** USFM codes are the published standard for exactly this and cover
the deuterocanonical books; keeping orders apart from membership lets one
canon be printed in more than one way without disagreement about what it
contains; and showing a full name rather than an unsourced abbreviation keeps
to D20's rule that facts are cited. The Greek Orthodox order is P3.1b.

### E28. Versification: one file per scheme, counted from public-domain texts

*2026-11-01, agent.* Each versification scheme is a plain file in
`catalog/scripture/versification/`, one line per book: its USFM id, its first
chapter, and each chapter's verses as a count or, where a chapter does not
start at verse 1, a range (the King James Rest of Esther starts at 10:4).
`Versification` in `ReadingEngine` reads it, and the catalog compiler checks
that every book it numbers is registered and every book a canon lists is
numbered (material a canon includes inside another book, such as the Letter
of Jeremiah as Baruch 6, may be numbered as part of that book).

The English (KJV) scheme is counted from eBible.org's public-domain 1769
King James Version, with Apocrypha, by `scripts/versification.swift
generate`; `compare` lists every difference from the World English Bible and
from TVTMS's tests (catalog/SOURCES.md). The script reads downloads in the
gitignored `research/` folder, so it is run when the counts are regenerated,
not by `make check`; the tests pin the totals (1,189 chapters and 31,102
verses for the 66 books) and the places where schemes differ.

Hebrew, Greek, and Latin numbering will be mappings from TVTMS (P3.2b), kept
as data derived from it under CC BY 4.0. The TVTMS file itself is never
committed or served, as its header asks.

**Why:** a count is a fact about a text's divisions, so counting from a
public-domain text and checking against two independent sources gives cited
numbers without copying anyone's table; and a file per scheme keeps each
scheme's differences reviewable line by line.

### E29. The leaner path: two gates, and web progress kept in the browser

*2026-11-01, agent, carrying out D39 (owner, 2026-11-01).*

- **Two gates.** `make check` (the toolchain, formatting, imports, tokens
  and colors, the catalog, the package and server tests, the app's unit
  tests, and the String Catalog) runs before every commit. `make
  check-full` adds the web tour, the app tour, and `make test-linux`, and
  runs at each milestone and before every TestFlight build or deploy (and
  in CI, which runs the web tour beside `make check`). The appearance and
  text-size matrix of AGENTS.md §7 is checked then, not on every item.
- **Web progress in the browser.** At 1.0 the web app keeps the reader's
  enrollments and journal events in the browser's own storage (IndexedDB),
  never in a cookie. To show Today, Progress, or a return preview, its
  JavaScript sends those records to the server in the request body; the
  server folds them with `ReadingEngine`, answers, and keeps nothing, and
  its logs record request metadata only. So the engine stays the single
  implementation (E4), nothing about a reader's reading reaches the
  server's storage (D10), and export is the browser's records as JSON. The
records do pass through the server while it computes, over HTTPS, and the
privacy page says so plainly (P16.3); if that ever proves unwelcome, the
engine can run in the browser as Swift compiled to WebAssembly instead.
  P8.10 builds it; accounts and sync replace the browser as the place of
  record after 1.0 (P28.8, Phase 14).

**Why:** the full tours and the Linux run take minutes and catch little
that the unit tests and a look at the change do not, so they belong at the
points where a build reaches someone. Keeping web progress in the browser
removes consent records, profile expiry, server backups, and cookies from
1.0 without moving any reading logic into JavaScript.

### E30. Passages are verses, and plan files have one way to write them

*2026-11-01, agent.* A `Passage` in `ReadingEngine` is a run of verses in
one book, from a first verse to a last, checked against a versification
scheme when it is made and carrying that scheme's name; a `Reading` is one
or more passages in the plan's order. Whole chapters are stored as their
verses, so `GEN 1` and `GEN 1:1-31` are the same passage, and "whole
chapters" is a question asked of the scheme (the King James Rest of Esther's
tenth chapter, whole, is 10:4–13).

Plan files write readings in one strict format (`ReferenceFormat`): USFM
ids, `GEN 1`, `GEN 1-2`, `JHN 3:16`, `JHN 3:1-21`, `JHN 3:16-4:3`, joined by
`; `. Anything else is refused with the reason, including a range written
longer than it needs to be (`GEN 2-2`, `JHN 3:1-3:21`). The reader sees
`ReferenceFormatter`'s wording under their naming convention (D29), with an
en dash: whole chapters as chapters, a single psalm as "Psalm", and a
one-chapter book by its verses alone ("Jude 3–5", or "Jude" for all of it),
as the SBL Handbook cites them. Repeating the book name before each
passage ("Psalm 119:1–24; Psalm 120") is an app convention, chosen for a
reader finding the place in print.

**Why:** storing verses gives every later step (verse sets, word counts,
coverage, links into Bible apps) one shape to work with and makes equal
passages compare equal; one writing per passage makes plan files easy to
review and leaves a parser for other sources' citation styles (P28.1) as a
separate job.

### E31. Word counts from the World English Bible, numbered by the English scheme

*2026-11-01, agent.* Workload estimates count words from eBible.org's
public-domain World English Bible, stored as a number per verse in
`catalog/scripture/words/web.tsv`, numbered by the English (KJV) scheme so
every passage can be counted. `scripts/wordcounts.swift generate` writes
the file from the gitignored download and states the method: a verse's
words follow its `\v` marker, footnotes, cross-references, and headings
are not counted, a psalm's title counts toward its first verse, and a word
is a run between spaces or dashes holding a letter or digit. The WEB's
Romans doxology (14:24–26) is counted as 16:25–27, and the four verses the
WEB gives only in footnotes (Luke 17:36; Acts 8:37, 15:34, 24:7) count no
words. `WordCounts` in `ReadingEngine` reads the file, and the catalog
compiler refuses one that does not fit the scheme. The 66 books come to
754,449 words, about 2,070 a day for the Bible in a year.

**Why:** the WEB and the Berean Standard Bible are both public domain
(Research finding 5), but the WEB was already downloaded and checked
against the English scheme (E28), and its numbering differs only in where
Romans' doxology sits. A modern translation is closer to what most readers
read than the KJV, which runs to roughly 780,000 words (Research finding
6) against the WEB's 754,449. The deuterocanonical
books wait for the plan that needs them (P10.12).
