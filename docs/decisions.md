# Engineering decisions

A numbered, append-only log of engineering decisions for Day by Word. Product
decisions are the owner's and live in BUILD.md's Owner decisions table
(D1–D42); this file records how they are carried out and why.

**How to use this file.** Add a new entry at the end with the next number,
the date, who decided (`agent` or `owner`), the decision, and the reasons.
Never edit or delete an old entry's decision. To change one, add a new entry
that supersedes it, and add a single line under the old entry pointing to
the new one (*Superseded by E12*). Every third-party package needs an entry
here before it is added (AGENTS.md §5).

**Current direction:** D42 (E36) and E33's engine boundary (E37) govern,
and E46 sets how the site runs on the host;
D40/E32 are withdrawn. Old implementation entries below record the Swift
server that PM.20 retired; do not use them to select the stack for new
work. Pure product/data rules remain in force.

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

*Implementation superseded by E32 (D40), then E33: one specification,
docs/engine.md, with a Swift and a TypeScript runtime (E37); retain the
applicable behavior and data invariants.*

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

*Implementation superseded by E32 (D40); retain the applicable behavior and
data invariants.*

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

*Implementation superseded by E32 (D40); retain the applicable behavior and
data invariants.*

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

*Implementation superseded by E32 (D40); retain the applicable behavior and
data invariants.*

*2026-10-30, owner (Engineering foundation 9, D5).* The system `SQLite3`
library is used through `ReadingData`'s own small wrapper on iOS and on
Linux, for the catalog, the app's journal, and the server's databases. WAL
mode is used on the server, with migrations versioned in code.

**Why:** one storage engine on every platform, no database server to run,
simple backups (the online backup API), and no third-party driver.

### E10. Few dependencies

*Implementation superseded by E32 (D40); retain the applicable behavior and
data invariants.*

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

*Implementation superseded by E32 (D40); retain the applicable behavior and
data invariants.*

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

*Implementation superseded by E32 (D40); retain the applicable behavior and
data invariants.*

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

*Implementation superseded by E32 (D40); retain the applicable behavior and
data invariants.*

*2026-10-30, owner (Engineering foundation 14); the last sentence is the
agent's.* Debug builds accept `-today YYYY-MM-DD`, and the development
server accepts `?today=YYYY-MM-DD`, so tests and screenshots can pin any
day. Release builds and the production server ignore both.

**Why:** schedules depend on the date, and a test that depends on the real
date is a test that fails next month.

### E15. Internationalized from the start

*Implementation superseded by E32 (D40); retain the applicable behavior and
data invariants.*

*2026-10-30, owner (Engineering foundation 15).* Every interface string goes
through a String Catalog on Apple platforms and the server's string tables
on the web, English first.

**Why:** retrofitting localization means touching every screen; doing it from
the first screen costs almost nothing.

### E16. Swift on the server: Hummingbird 2 and SQLite

*Retired by PM.20 (2026-11-20): `Server/` is removed; SvelteKit is the only
server (E36, E38).*

*Implementation superseded by E32 (D40); retain the applicable behavior and
data invariants.*

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

*Implementation superseded by E32 (D40); retain the applicable behavior and
data invariants.*

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

*Retired by PM.20 (2026-11-20): `Server/` is removed; SvelteKit is the only
server (E36, E38).*

*Implementation superseded by E32 (D40); retain the applicable behavior and
data invariants.*

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

*Retired by PM.20 (2026-11-20): `Server/` is removed; SvelteKit is the only
server (E36, E38).*

*Implementation superseded by E32 (D40); retain the applicable behavior and
data invariants.*

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

*Implementation superseded by E32 (D40); retain the applicable behavior and
data invariants.*

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

*Implementation superseded by E32 (D40); retain the applicable behavior and
data invariants.*

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

*Implementation superseded by E32 (D40); retain the applicable behavior and
data invariants.*

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

*Implementation superseded by E32 (D40); retain the applicable behavior and
data invariants.*

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

*Implementation superseded by E32 (D40); retain the applicable behavior and
data invariants.*

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

*Implementation superseded by E32 (D40); retain the applicable behavior and
data invariants.*

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
one-chapter book by its verses alone ("Jude 3–5", or "Jude" for all of it).
The last two, and repeating the book name before each passage ("Psalm
119:1–24; Psalm 120"), are app conventions, not rules from a cited source:
a one-chapter book has no chapter to look for, and a reader finding the
place in print is helped by the book's name each time.

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

### E32. The unified stack, local shared engine and migration precedence

*Withdrawn before implementation; superseded by E33 under final D41.*

*2026-11-02, owner (D40); implementation plan recorded in Phase M and
docs/stack-migration.md.* This is a planned replacement, not a completed
migration.

- Next.js App Router/React/TypeScript with Tailwind and shadcn/ui replaces
  Hummingbird/HTML strings/vanilla modules. Build standalone Node output in
  Docker Compose behind the existing host Caddy; no hosted platform is
  required. Expo/React Native replaces the main SwiftUI app. Preserve iOS
  26 minimum, App Store identity, native extension capabilities and Morning.
- One pure TypeScript engine replaces the Swift packages' reading logic,
  imported by server, mobile, browser offline code and compiler. Native
  widgets/actions may use small adapters around snapshots/commands, with
  no second scheduling/fold implementation. Verify their runtime boundary.
- Drizzle owns server PostgreSQL schema and reviewed, committed migrations.
  Its initial data is public catalog content, not reader history. A
  deterministic versioned catalog artifact replaces runtime Catalog.sqlite,
  imported into Postgres and bundled/cached on clients. Preserve source
  formats, numeric data, compiler validation, rights and review filters.
- The Expo device uses local SQLite and the browser IndexedDB. Clients
  call Next APIs for network services, never Postgres. Local shared-engine
  evaluation replaces E29's requirement to send reading records to the
  server to compute; no account or network is required for local reading.
  A genuinely necessary stateless endpoint may compute transiently under
  the same no-storage/no-body-logging rule. Consent still gates future sync.
- Better Auth with its Drizzle/Postgres adapter is selected for Phase 14,
  retaining optional passkeys/recovery and the no-email/no-password product
  requirement. Validate that flow and mobile support when the phase opens.
  No auth service or schema is installed solely for migration. Stripe
  waits for a real billing need. Tauri is the future desktop choice if
  needed; Android remains after 1.0 using Expo. D23 excludes AI SDKs.
- Pin the compatible toolchain/workspace/test dependencies at PM.2 and
  record exact versions and any additional package choices before adding
  them. Port fixtures from the old implementation first. Maintain legacy
  checks while targets are active; the final Make/CI gate tests Node,
  PostgreSQL, production standalone output and native Expo builds.
- Keep strict production nonce CSP, no external loads or telemetry,
  metadata-only logs and private DB networking. Backups become nightly
  pg_dump plus encrypted off-server copy and isolated restore testing from
  the first DB deployment. D34 still restricts changes to this project.

**Why:** the owner wants the same core stack across projects. Sharing
TypeScript preserves one implementation across offline clients and the
server. Keeping local stores and deferring auth retains the approved
privacy and 1.0 scope, while PostgreSQL supplies the requested server data
layer. Phase M ports the foundation, not the unbuilt features. Completed
phases and old entries remain historical evidence rather than being
rewritten as if the new implementation had already passed.

**Supersession:** implementation details of E4, E6–E16, E18–E26 and E29
yield to this entry where they specify Swift, Foundation, SQLite on the
server, Hummingbird, XcodeGen, no npm/frameworks, old test tooling or
server-only computation. E1/E29's gate cadence, E2/E3's version/journal
invariants, E5's compile-time calendars, E7's civil dates, E8's local-first
rule, E17's privacy, and E27–E31's source/reference/count semantics survive.
No old decision is evidence that a new-stack check has passed.


### E33. Final Astro/PostgreSQL stack; languages only for demonstrated needs

*Web framework superseded by E36 (D42, 2026-11-20): read "Astro" as
SvelteKit. The engine boundary, data and language rules below stand.*

*2026-11-02, agent implementing the owner's final D41 correction.* This is
a documentation plan; no runtime migration has happened. E32's Next/Expo
and all-TypeScript proposal is withdrawn. Earlier implementation
supersession pointers through E32 now resolve to this entry.

Astro/TypeScript with the Node standalone adapter replaces Hummingbird's
HTTP layer. PostgreSQL/Drizzle replaces server SQLite. Public pages can
prerender; Actions/endpoints handle server work and Swift clients. React
islands/Tailwind/shadcn are optional per UI need. Docker Compose, host Caddy,
Caddy's own TLS on owner-managed DNS-only Cloudflare records, private DB/roles and nightly pg_dump/off-server restore
verification remain. No SQLite server replication or Litestream.

The existing Apple app justifies SwiftUI/Observation and its pinned Swift
toolchain. Keep its native domain/data/compiler packages, WidgetKit and
App Intents, identity and offline local SQLite. No Expo/Tauri rewrite.
SwiftData/GRDB require an actual need and dependency decision; a native Mac
target is still later work. Python is not mandatory. If utility work
needs it, use uv/ruff and task-specific dependencies; Postgres reports
cannot use sqlite3 file access.

**Engine boundary choice:** replacing the HTTP layer with Astro while
retaining native Swift removes the former same-language engine advantage.
Use one specification and versioned oracle fixtures with a Swift native
engine and a pure TypeScript web engine. This replaces E4's literal
single-implementation rule; it does not permit business rules in views,
routes, SQL or scripts. Cross-runtime parity is a required gate for every
rule. This avoids a new Swift HTTP/worker service as a hidden requirement
of the Astro runtime; it costs two domain implementations and stronger
parity maintenance. Record mismatches and resolve against the specification,
not by silently changing one client's result. Preserve existing Swift
reference/compiler tests before porting TypeScript behavior.

Catalog source files, numeric data, source rights, release filters and
immutable ids remain authoritative. Define a deterministic export/import
contract for the existing compiler's schema-3 catalog; Drizzle owns the
server schema/migrations, while bundled native catalogs remain rebuildable
read-only artifacts. Do not derive a new plan or claim during migration.

D10/D39 local privacy, append-only records, civil dates and milestone gates
remain. Server data at 1.0 is public catalog only. Better Auth/Astro with
Drizzle/Postgres is the later optional account implementation; verify
passkey-only/recovery behavior then. D23 excludes model features/SDKs.
PM.12–PM.20 replace the withdrawn PM.1–PM.11. Future agents pin exact
versions and additional packages before implementation. No new stack
checks, deploy or upload is claimed by this decision.


### E34. The web workspace's toolchain and packages

*Packages superseded by E36 (2026-11-20); the Node/npm pins, exact
versions, lockfile and gates below stand.*

*2026-11-08, agent (PM.13).* `web/` is an npm workspace pinned to
**Node 26.13.0** (`.node-version`, Active LTS since October 2026) and
**npm 11.20.0** (`packageManager`, `engines` with `engine-strict`), with
exact versions (`save-exact`) and a committed `package-lock.json`.
`scripts/check-toolchain.sh` refuses any other Node or npm.

Runtime packages: **astro 7.4.7** and **@astrojs/node 11.1.11** (server
output, standalone mode). Development packages: **@astrojs/check 0.9.12**
and **typescript 6.0.3** for `astro check`; **@types/node 26.6.6**;
**vitest 5.1.0** for unit tests; **eslint 10.14.0**, **@eslint/js 10.0.1**,
**typescript-eslint 8.72.1** and **eslint-plugin-astro 3.2.1** for lint;
**prettier 3.9.10** and **prettier-plugin-astro 1.1.2** for formatting.

**Why these:** each is the official or standard tool for its job in an
Astro project, and nothing else was added (no React, Tailwind, shadcn or
Playwright yet: each waits for a demonstrated need, E33). TypeScript stays
on 6.0 because @astrojs/check (`^5 || ^6`) and typescript-eslint
(`<6.1`) do not yet support TypeScript 7.0; move when both do. Astro's
telemetry is disabled by `ASTRO_TELEMETRY_DISABLED=1` in the Makefile,
its development toolbar is off, and `session: false` removes the Node
adapter's filesystem session store, since the server keeps no reader data
at 1.0 (D10, D39). fsevents' install script is left unapproved: it is an
optional macOS file watcher the build does not need.

`make check` now runs `check-web`: eslint and prettier, `astro check`
failing on warnings, vitest, the production build, and
`scripts/web-smoke.sh`, which boots `dist/server/entry.mjs` on a free
loopback port and checks `/up` against the captured fixture, a
prerendered `/`, no cross-host loads, and a 404. CI (manual, D31) sets up
the pinned Node and npm on macOS and adds a Linux `make check-web` job.


### E35. The PostgreSQL catalog: packages, versions, and the import boundary

*PostgreSQL 17 became 18 under E36 (2026-11-20); the boundary stands.*

*2026-11-08, agent (PM.14).* Packages: **drizzle-orm 0.45.4** and
**pg 8.23.1** (runtime, server-only), **drizzle-kit 0.31.11** and
**@types/pg 8.23.1** (development). They are the stable releases; Drizzle's
1.0 is still a release candidate, so it waits. node-postgres is the
reference driver and needs no native build. PostgreSQL **17** is the
server major, matching the Homebrew `postgresql@17` already here; the
deploy image (PM.18) must use the same major.

**The boundary.** The Swift compiler stays the rights and claims gate and
writes a deterministic JSON export of the compiled schema-3 catalog
(`catalog export`); the TypeScript importer recomputes the compiler's
content checksum, refuses anything a release may not serve, and writes the
export in one locked transaction. A JSON document was chosen over reading
the SQLite file from Node, which would add a SQLite driver to the web
image (AGENTS.md §5 forbids server SQLite access) and tie the server to
the file's bytes. Plans are immutable by (id, version), enforced by the
importer and by triggers; `catalog_current` alone moves, which makes
re-imports no-ops and a rollback a re-import. Two roles from
`web/db/roles.sql`: the web reads; only the one-shot jobs write.

**Compatibility.** Migrations are additive while two builds may share a
database, and a job refuses a database with migrations it does not know.
The first two migrations create everything; nothing older exists, so no
upgrade path was tested yet. `make test-db` uses a throwaway cluster on a
Unix socket (`scripts/with-postgres.sh`) rather than Docker, so `make
check` needs no container runtime.

`npm audit` reports two development-only advisories: esbuild ≤0.24.2's
development server (inside drizzle-kit's loader; Day by Word never runs
esbuild's server) and minimatch's glob amplification (inside
typescript-eslint). Production dependencies have none. Revisit when
drizzle-kit and typescript-eslint update. esbuild's install scripts stay
unapproved; drizzle-kit runs without them.


### E36. SvelteKit 3, Svelte 5, Tailwind CSS 4 and PostgreSQL 18

*2026-11-20, agent carrying out the owner's D42.* The stack is SvelteKit 3
· Svelte 5 · TypeScript · Tailwind CSS 4 · PostgreSQL 18 + Drizzle ORM ·
Node (adapter-node) · Caddy. It replaces E33's Astro web, its optional React
islands and shadcn, and E34's Astro packages. E33's engine boundary (one
specification, Swift and TypeScript runtimes, shared fixtures), E35's
catalog import boundary, and every privacy, rights and language rule stand.

**Packages** (exact, `web/package.json`): **@sveltejs/kit 3.4.0**,
**svelte 5.58.0**, **@sveltejs/vite-plugin-svelte 7.3.1**, **vite 8.3.8**,
**@sveltejs/adapter-node 6.0.5**, **tailwindcss 4.3.5** with
**@tailwindcss/vite 4.3.5**; checks **svelte-check 4.7.8**,
**eslint-plugin-svelte 3.24.1**, **prettier-plugin-svelte 4.2.0** and
**prettier-plugin-tailwindcss 0.8.1** (sorts classes; reads
`src/app.css`). All are development dependencies: adapter-node bundles
them into the server. drizzle-orm and pg stay the runtime dependencies,
installed in the image, because adapter-node leaves `dependencies`
external. Kept from E34/E35: Node 26.13.0, npm 11.20.0, TypeScript 6.0.3
(SvelteKit 3.4 requires ^6, so 7.0 still waits), vitest, eslint,
typescript-eslint, prettier, drizzle-kit. Removed: astro, @astrojs/node,
@astrojs/check, eslint-plugin-astro, prettier-plugin-astro. svelte 5.58.1
was published hours before this choice, so 5.58.0 was pinned.

**Shape.** SvelteKit 3 reads its options from the `sveltekit()` Vite
plugin in `web/vite.config.ts` and no longer from svelte.config.js;
tsconfig extends `$app/tsconfig` and must list `$app/types` in `types`.
Server-only code is `src/lib/server/` (SvelteKit 3 refuses to import any
`server` directory into browser code, which enforces AGENTS.md §5's
no-database-in-clients rule at build time); the domain module will be
`src/lib/domain/`. SvelteKit 3 no longer generates `$lib`: `#lib/*` is a
Node subpath import in `web/package.json` (`imports`), which Vite,
TypeScript and plain Node all resolve, so the jobs and tests use it too,
with file extensions. Its other changes that later items meet:
`$app/env/private` replaces `$env/…`, `$app/state` replaces
`$app/stores`, and `csrf.trustedOrigins` replaces `csrf.checkOrigin`. Routes:
`+page.svelte`/`+page.server.ts`, form actions for forms, and
`src/routes/api/v1/**/+server.ts` for the app and browser. The one-shot
jobs stay plain `node scripts/*.ts` with relative imports, so they need no
bundler. adapter-node writes `web/build/` (`node build/index.js`, `HOST`
and `PORT`; behind Caddy it needs `ORIGIN=https://daybyword.com` for form
actions' origin check; `BODY_SIZE_LIMIT` bounds request bodies).
`precompress` writes Brotli and gzip copies of static assets.

**Styling.** Tailwind CSS 4 through its Vite plugin, one entry at
`src/app.css`. Morning stays the design (D18): PM.16 generates its tokens
from design/tokens.json into Tailwind `@theme` variables, so utility
classes use Morning's names and no raw colors are added. No component kit:
shadcn is React-only, and its Svelte ports are not needed for this UI.

**CSP.** SvelteKit's `csp` option hashes its inline bootstrap script in
prerendered pages and uses nonces in rendered ones, which keeps the
production policy free of `unsafe-inline`; Svelte transitions that write
inline styles must be avoided or checked under the policy. PM.16 sets and
tests it in the built server, not the dev server.

**PostgreSQL 18.** The deploy image and `scripts/with-postgres.sh` use
major 18 (Homebrew postgresql@18 18.6 here). No database existed on 17,
so nothing is upgraded; the migrations, triggers and roles passed
`make test-db` on 18 unchanged.

**Why:** the owner chose this stack for the project. SvelteKit covers what
E33 needed from Astro (server rendering, selective prerendering, form
handling, API endpoints, a standalone Node server) and gives interactive
pages one component model instead of islands in a second framework.
Telemetry: SvelteKit, Vite and Tailwind send none, so the Makefile's
`ASTRO_TELEMETRY_DISABLED` was removed. `npm audit` still reports only the
development-only advisories E35 recorded; production dependencies have
none.


### E37. The engine's two runtimes are checked in Node and in a real browser, with no new packages

*2026-11-20, agent (PM.15).* `docs/engine.md` (version 0) specifies what
Swift's `ReadingEngine` already does, and `web/src/lib/domain/` is its
TypeScript runtime: pure modules (the lint refuses imports from outside the
folder and DOM, Node, storage and network globals) that take the scripture
files' text, as Swift's callers pass `Data`. The shared cases are checked
three ways: Swift `FixtureTests` and vitest in Node on every `make check`,
and `make test-domain-browser` in `make check-full`, which builds
`web/test/browser/` with Vite, serves it on loopback and reads its result
from headless Firefox through geckodriver. A new fixture,
`scripture-files.json`, pins how both runtimes refuse malformed registry,
versification and word-count files, recorded from Swift.

**Why:** Vitest's browser mode or Playwright would each add packages and a
browser download for one page of checks; Vite and geckodriver are already
here (E26, E36), and the page uses the same comparison as the Node test, so
the two cannot drift. Firefox alone is automated: Safari needs "Allow remote
automation", a setting agents do not change; Chrome and Safari are covered
by the web tours later (P15.6). Recording the refusals as a fixture rather
than porting Swift's unit tests keeps one list of invalid inputs, which
found one subtlety at once: Swift's versification reader skips extra spaces
between chapters while its word-count reader refuses them.


### E38. The SvelteKit pages: server-rendered, no client runtime yet, and one server wrapper for headers

*2026-11-20, agent (PM.16).* Every page the Swift server rendered is now a
SvelteKit route rendered on the server per request: the layout, Today,
Plans, a plan and its week (plan ids matched in `src/params.ts`), Progress,
Settings, the 404 page, and the component gallery at `/dev/components`
(only under `vite dev` or `DBW_ENV=development`). The eleven shared
components are Svelte 5 components; the strings are `src/lib/strings.ts`,
equal to tests/fixtures/strings.json; Morning's tokens are generated into
Tailwind CSS 4 theme variables (`web/src/tokens.css`, `make tokens`), with
Tailwind's own palette removed so a class can name only a token color.

**No client runtime yet.** SvelteKit 3.4's root component writes its route
announcer with a fixed inline `style` attribute (`root.svelte`), which
`style-src 'self'` refuses and which no option turns off. Rather than
weaken the policy (`'unsafe-hashes'` or `'unsafe-inline'` on
`style-src-attr`), every page sets `csr = false` and ships no SvelteKit
JavaScript. Settings, the copy buttons and the old-browser notice keep the
Swift site's small same-origin modules (`static/assets/settings.js`,
`copy.js`, `support.js`, `unsupported.js`, `theme.js`), with a test that
they use the fixture's storage keys. When a page needs real interaction
(P8.10's Today and marking), choose then among: mounting Svelte
components with `mount()` from a Vite entry outside SvelteKit's router (no
announcer), a SvelteKit release that sets the announcer's style through
the CSSOM or a class, or an upstream fix; never a weaker policy.

**One server wrapper.** `web/server.ts` runs adapter-node's handler inside
`node:http` and adds the Swift server's security headers to every
response, static files and errors included (SvelteKit's own CSP, with its
nonce, wins on pages it renders), a cache policy (fingerprinted files keep
adapter-node's year, the site's other files an hour, pages and errors
`no-cache`, `/up` and `/api/v1` `no-store`), and one log line per request
of method, route pattern, status and milliseconds: `hooks.server.ts` marks
the pattern in a header the wrapper removes before sending, and static
files log as `static`. Hooks alone could not reach static files or
adapter-node's redirects.

**Differences from the Swift server**, each tested in
`web/test/production/server.test.ts`: `/today/` redirects (308) to `/today`
instead of answering 200 (docs/urls.md has no trailing slashes);
`/assets/site.css` and `/assets/tokens.css` are gone, their rules now in
one fingerprinted stylesheet (they were the site's own files, never
linked from outside, docs/urls.md); `/favicon.ico` is `image/x-icon`;
`/api/v1/…` answers a JSON 404. Everything else in routes.json, the
headers included, answers as before.

**Why:** server rendering keeps every page readable with no JavaScript
(D30) and the CSP strict (E11) with no exceptions; the interaction 1.0 has
so far is two small scripts that already worked. A wrapper of a few dozen
lines is smaller than a Caddy rule set kept in step with the app, and the
headers stay with the code that is tested.


### E39. Deploying with Compose and shell, rehearsed in Docker before the host

*2026-11-20, agent (PM.18).* `deploy/` holds the image, the Compose project,
the Caddy site file, systemd timers and POSIX shell scripts (deploy,
rollback, check-live, backup, restore check, rehearse), listed in
docs/deploy.md. Choices: the image is built on the host from a release
directory that already holds the catalog export, so no Swift toolchain is
needed there; base images are pinned by multi-platform index digest; the
web container runs as `node` with a read-only root, no capabilities and
memory and process limits, on loopback only; PostgreSQL has no host port
and sits on an internal network; a candidate is checked on a spare port
before the live service is switched; rollback switches images and never
restores over the live database (migrations stay additive, E35); `/up`
reports ready only once the web role sees a current catalog. Backups are
custom-format `pg_dump`s with a checksum and manifest kept 14 days; the
monthly restore check uses a throwaway, network-less PostgreSQL. The
scripts take the host's lock path rather than inventing one (P7.1).

**Why:** shell and Compose are already on the host and need nothing
installed; every step can be rehearsed end to end on the Mac
(`make rehearse-deploy`, which found that a release tag is not a valid
`DBW_COMMIT` and that Compose resolves every image tag even to exec), so
P7 meets only the host's own questions: its lock, Caddy include, free
port and backup entry.

### E40. The scheduling model: a fold over events, counted targets, and wall-clock reminders

*2026-11-20, agent (P5.1).* docs/engine.md's version 1 specifies schedules,
the journal, progress and reminders. Its choices, each among alternatives:

- **Journal order is id order, and impossible events are inert.** Events
  sort by their UUIDv7 text, so the fold is the same in any arrival order
  (E3). An event that can mean nothing (an unknown assignment, an undo
  with no target) is kept and does nothing, with a reason reported, rather
  than refusing the whole journal: a reader's history must stay readable
  after a client bug. Only a malformed event or two different events under
  one id refuse it.
- **A settled reading moves the plan on.** Read, partly read and skipped
  are all answers; "next" is the first unread reading. The alternative,
  holding a partly read reading as next until it is finished, makes the
  reader skip to go on, and a skip is not what they did.
- **Finish dates use counted targets, not a date per reading.** A basis
  (first day, finish, readings unread) gives each scheduled day a target
  count, spread evenly in whole readings. Late logging and undo then
  change only how many are settled, never which reading belongs to which
  day, and redistribution is one new basis the reader previews and
  accepts, never automatic. Today never shows more than a day's share, so
  a backlog is not put on one day (AGENTS.md §3).
- **Short months appoint fewer readings** in a day-of-month plan; the 29th
  to 31st are not added to the last day, which would change a day's
  workload unasked. The interface says so plainly (P10.7).
- **The welcome after a gap needs two missed reading days**, not one: a
  missed day is simply a day.
- **Reminders are wall-clock in and out.** The engine takes the local date
  and time and returns local fire times; the device schedules them by
  wall-clock time. So the engine needs no time zone database, the two
  runtimes cannot disagree over one, and daylight saving changes are the
  system's to deliver (tested end to end in P17.4).
- **No date-in-the-year schedule at 1.0.** The catalog format has
  `sequence` and `day-of-month`, and none of the eight launch plans is
  keyed to dates in the year, so that kind waits for a plan that needs it
  (P28.4).

**Why:** each keeps the record honest (nothing rewritten, nothing counted
that was not read) and the rules small enough for two runtimes to hold to
one set of cases (E33).

### E41. Civil dates: our own calendar arithmetic, with the time zone at the edge

*2026-11-20, agent (P5.3).* `CivilDate` (Swift) and `civil-date.ts` count
days from 0001-01-01 in the proleptic Gregorian calendar with integer
arithmetic of their own, written fresh (D22). Turning an instant into a
date in a time zone is kept out of the engine: `CivilDate+Foundation.swift`
uses Foundation's calendar, and `web/src/lib/today.ts` uses `Intl`, each
tested on its own.

**Why:** the alternative, Foundation's `Calendar` and JavaScript's `Date`
for all date arithmetic, ties every rule to a time zone and to two
libraries that differ (Foundation's Gregorian calendar is Julian before
1582). Whole-day integer arithmetic is the same in both runtimes, is
checked against every date from year 1 to 9999 and against both libraries
for 1583 to 2400, and leaves the zone in one small place per client (E7).

### E42. The journal's fold: inert in journal order, a hand-read wire form, and one basis

*2026-11-20, agent (P5.2, P5.4).* Building the fold settled what E40 left
open:

- **Whether an event is inert is decided at its place in journal order,
  from the events before it, and never changes.** The alternative, judging
  every event against the journal's final state, would make a reading
  marked while a plan was un-ended vanish when the reader ended it again.
  Whether an event is *active* (not undone) is still a matter of the whole
  journal: two undos of one event are one undo.
- **The wire form is read field by field** through a small `JSONValue` in
  Swift and plain objects in TypeScript, in one stated order, rather than
  through `Codable` and a schema library. Both runtimes then name the same
  first fault in the same words, `true` is never taken for 1, and no
  package is added.
- **What refuses a journal can be told from one event alone** (a field
  missing or of the wrong type), or from two copies under one id.
  Everything that depends on the rest of the journal is inert instead, so
  a reader's history stays readable (E40).
- **`finish` and `remaining` travel together and are not dated.** They set
  a schedule's basis; the arrangement on a date holds only the behavior,
  reading days, limit and reminder. Otherwise a finish date could be read
  two ways.
- **Ids are checked, never parsed for meaning beyond their milliseconds**,
  and the engine makes one only from a millisecond count and random bytes
  the client supplies, so it stays a pure function.

**Why:** the fold must give two runtimes, and any arrival order, one
answer (E3, E33), and must never lose what a reader recorded.

### E43. The database container's files live outside every release

*Superseded by E46.*

*2026-11-20, agent (P7).* The `postgres` service mounted its first-start
hook and `web/db/roles.sql` from the release directory. On the host every
release is unpacked into a directory of its own, so the mounts' paths
changed with each deploy, Compose saw a changed container, and every
deploy recreated the database: a few seconds without it, no data lost.
The rehearsal missed it because it deployed twice from one directory.

Now the two files are mounted from a fixed directory,
`/srv/www/daybyword.com/shared/postgres` (`DBW_DATABASE_FILES`), which
`deploy/bin/deploy.sh` keeps current by writing them in place, and
`deploy/bin/rehearse.sh` deploys its second release from another
directory and fails if the database container's id or start time changes
across that deploy or the rollback.

**Why:** the alternative, `docker compose up --no-recreate`, would stop
the restarts but leave the running container mounting files from an old
release directory, which a later cleanup of old releases would remove
from under it; and it would hide a real change to the service the day
one is meant. A fixed path makes the container's definition independent
of the release, which is what "the database outlives every release"
means (E39).

### E44. Progress and reminders: what building them settled

*2026-11-21, agent (P5.11, P5.12).* Version 1 of docs/engine.md is now
implemented in both runtimes. The choices E40 left open:

- **A day read is any active reading event's date**, not the date a slot
  now holds. A reading begun on Monday and finished on Tuesday is two
  days read, though the slot keeps Tuesday's mark. The alternative,
  going by each slot's last mark, would take Monday away when the reader
  finished the reading. Its cost is stated in a case: a reading marked
  read and then skipped with no undo leaves the day a day read until the
  reading is undone, so clients offer Undo, not Skip, on a read slot.
- **A finished sequence asks nothing after its last marked day.** Its
  later dates are not reading days for the recent days or the streak;
  otherwise finishing a plan would end a streak the next morning.
- **A calendar enrollment's total includes slots settled outside its
  appointed days** (on a paused day, or read ahead), so read, part read,
  skipped and unread always add up to the total.
- **Stated verses count only as far as they are the reading's own**, and
  text that is not a reading counts as none stated. Coverage cannot be
  inflated by a client's mistake.
- **A sequence's reminders all name its next unread reading.** Naming
  the second-next reading for tomorrow would be wrong whenever the
  reader does not read today; since every mark asks the engine again,
  the next reading as things stand is right on every day.
- **Quiet hours, the most a day and snoozes are device settings, not
  journal events.** They say how one device may interrupt, not what the
  reader arranged for a plan; only an enrollment's reminder time is in
  the journal. A snooze is kept while the enrollment's status today is
  `reading`.
- **A horizon of 366 days** bounds the search, so a reminder time that
  quiet hours drop every day ends the search instead of running on.

**Why:** each keeps the record what the reader did (product principle 5,
honest records) and keeps a notification from saying something untrue.

### E45. The web reads its catalog one way, everywhere

*2026-11-21, agent (P8.10a).* The plan pages read the catalog from
PostgreSQL as the web role, on the live host and on a developer's Mac
alike. `scripts/with-catalog.sh` starts a throwaway PostgreSQL 18 with
the roles, every migration and the release export, and `make serve-web`,
the production tests and the web tour run inside it.

The alternative was a second reader for local work, taking the export's
JSON straight from a file. It would have been quicker to start, and it
would have meant the pages seen and tested locally came through code the
live site never runs: a mistake in the SQL, the roles or the import
would first show on daybyword.com. One path costs a few seconds of
`initdb` per run and needs PostgreSQL 18 on the Mac, which `make check`
already did.

Two smaller choices on the pages themselves: **a sample week is the
engine's days ahead** for a reader who starts on a Monday that is also
the first of a month (2001-01-01), on the first of the week's days the
plan is paced for, so a sequence shows a week from Monday and a
day-of-month plan a month's first seven days, and the page says the
reader's own week depends on their start and their days; and **Plans
lists the shortest plan first**, by readings and then by title, until
P9.3 groups plans by goal. Neither ranks a plan by popularity (D23,
BUILD.md P9.2).

### E46. A native service on the host's PostgreSQL, deployed fix-forward

*2026-11-21, agent, carrying out the owner's web platform contract for the
host (`ubuntu-vm-backup/docs/web-platform.md`).* daybyword.com leaves its
Compose project: `daybyword-web.service` runs `/opt/node-26/bin/node
server.ts` from `/srv/www/daybyword.com/current` as `daybyword-web`, under
the contract's sandbox, against `daybyword` on the host's PostgreSQL 18
cluster. The image, the database container and its volume are gone (E43
described them). `web/` moves from npm to pnpm 12.18.0 (a native
executable; `pnpm import` wrote the lockfile from the npm one), Node goes
to 26.13.1, and the shared dependencies take the contract's baseline
versions.

- **Roles.** The host's model replaces `daybyword_migrate` and
  `daybyword_app`: `daybyword_owner` owns everything and cannot log in;
  `daybyword_migration` becomes it with `SET ROLE` (`DB_OWNER_ROLE` in
  `migration.env`) for migrations and the import; `daybyword_web` reads,
  with read-only transactions. `db/roles.sql` builds the same model in every
  test cluster, so the tests run as production's roles.
- **Schema app.** The host's roles have `search_path = app, pg_catalog`, so
  migration 0002 (hand-written: drizzle-kit can only ask interactively
  whether a table moved) moves the seven tables and the trigger function
  from public to app and grants the web role its reads; `schema.ts` names
  `pgSchema("app")`. 0000 and 0001 still create the catalog in public, so the
  migrator runs on one connection with `search_path` public; every later
  migration is qualified. Raw queries name `app.` themselves.
- **One database variable.** The server, the jobs and the tests read
  `DATABASE_URL` (`web.env`, `migration.env`), the contract's name, instead
  of `DBW_DATABASE_URL`.
- **Deploys.** `deploy/bin/build-release.sh` builds and checks on the host as
  the checkout owner; `deploy/bin/activate.sh`, inside the lock, backs up,
  migrates and imports as the service account, starts the release as a
  candidate under a copy of its own unit on a 44xx port, checks it, then
  switches and checks what is live. It keeps 52126aa's candidate-then-verify
  shape and drops its rollback branch, `rollback.sh` and the Docker
  rehearsal: a failed release is fixed by a new commit. Settings and
  `/healthz` show the commit from the release's `REVISION`.
- **Backups.** `backup.sh` and `restore-check.sh` keep their manifest and
  checks but dump the host cluster as postgres and restore into a throwaway
  cluster on a private socket; neither needs Docker. A dump is kept only
  after pg_restore can read it, because a shell redirect creates its file
  before pg_dump runs.

**Why:** the owner's one standard for every site on the host, and the
host's PostgreSQL stays listening on loopback only, which a container on a
bridge network cannot reach.

**Alternatives rejected:** keeping the tables in public with the roles'
search_path changed (a second exception to the contract on every role), and
renaming the old roles in place (the host's provisioning creates and proves
its own).


### E47. The app's journal: one SQLite file of wire-form events

*2026-11-21, agent (P8.2b, P8.3, P8.4).* The app keeps the reader's journal
in `Journal.sqlite` in Application Support, through `JournalStore` in
`ReadingData`: one table, `events (id TEXT PRIMARY KEY, wire TEXT)`, each
event in the wire form docs/engine.md defines, with `PRAGMA user_version`
for the schema. Writing an event whose id is already there changes
nothing, so a retry is harmless; the only removal is the reader's own
"delete all data" (P8.13). `Library` (apple/App/Model) opens it with the
bundled catalog, folds it with the engine after every write, and resolves
today once at the edge in the device's zone, again whenever the app
becomes active. A new event's id is a UUIDv7 a millisecond after the last
of its enrollment's when the clock has not moved on; `device` is the
device's kind ("iPhone"), never its name. Debug builds take `-today
YYYY-MM-DD` (E14) and `-freshJournal YES` for tests and screenshots.

**Why:** the wire form is the one the engine's shared cases already pin,
so the stored journal, an export (P8.13) and a later sync (P14) are the
same bytes, and a column per field would be a second schema to keep in
step with the engine. SQLite is already the app's store (E9, E18).

**Not yet:** the widget and notification actions need the journal in the
App Group container (P8.9, P12.1); the file moves there with them.

### E48. The signing team is committed, not kept in a local file

*2026-11-21, agent, at the owner's request to make TestFlight builds easy
for every session.* `DEVELOPMENT_TEAM = D9QMP3LP8H` moves from the
gitignored `apple/Config/Secrets.xcconfig` into `apple/Config/Base.xcconfig`.
`Secrets.xcconfig`, still gitignored and included after it, remains only as
an override. `make check-signing` (`scripts/check-signing.sh`) checks that
Xcode is installed, that the login keychain holds an Apple Development or
Distribution certificate whose organizational unit is that team, and that
Xcode is signed in to an Apple ID; `make archive` runs it first.

**Why:** a team ID is not a secret. Apple writes it into every signed app,
it appears in the app's provisioning profile, and docs/release.md already
published it. Keeping it in a local file only meant each new checkout or
Mac failed `make archive` until someone recreated a one-line file.
Certificates, profiles and the Apple ID stay out of the repository:
automatic signing (`-allowProvisioningUpdates`) fetches them through the
account Xcode is signed in with.

### E49. Opening a reading: one Bible.com address, and no default translation

*2026-11-21, agent (P8.5).* "Open in YouVersion" opens a Bible.com
address (`https://www.bible.com/bible/{version}/{BOOK}.{chapter}[.{verses}]`),
not the app's `youversion://` scheme. Apple's association file for
bible.com gives every path to the YouVersion app, so the one address opens
the app where it is installed and the website where it is not, on the
phone and on the web alike, with no check for the app (which would need a
`LSApplicationQueriesSchemes` entry and says nothing to a web page). The
rule (docs/destinations.md) is in ReadingEngine and the TypeScript domain
module with shared cases, because both clients build the same links.

**No default translation.** Bible.com needs a version in the address, and
picking one for the reader would put one translation forward as the norm
(AGENTS.md §3). The reader chooses from 22 English translations, listed by
name in alphabetical order and each checked on Bible.com; until then
Today offers Copy reference and a way to choose.

**Why:** one address is one thing to test and to record; universal links
are Apple's own mechanism for exactly this; and a choice the reader makes
once is better than a default that is wrong for most of them.
