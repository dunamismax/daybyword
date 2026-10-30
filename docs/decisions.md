# Engineering decisions

A numbered, append-only log of engineering decisions for Day by Word. Product
decisions are the owner's and live in BUILD.md's Owner decisions table
(D1–D38); this file records how they are carried out and why.

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
