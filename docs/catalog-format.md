# The catalog format

Every plan is one plain-text file in `catalog/plans/`, named for its id
(`catalog/plans/gospels-at-your-pace.plan`), written so it can be reviewed
line by line (E13). The compiler (`make catalog`, BUILD.md P4.3) reads it,
checks every reference and claim, and writes it into `Catalog.sqlite`;
nothing reads plan files at run time. The scripture data it is checked
against is described in `docs/scripture.md`, and its rights in
`catalog/SOURCES.md`.

## Final stack alignment

D41 retains the source grammar, native read-only catalog and compiler
rights/claims checks below. The SQLite schema-3 catalog stays the app's
bundled artifact; the server reads the same content from PostgreSQL through
the export below ("The export", "The server catalog", PM.14). Do not migrate
the native catalog into a remote DB or weaken release review filters.

## A plan file

Front matter of `key: value` lines, a line holding only `---`, then the
schedule. Lines starting with `#` are comments anywhere, and blank lines
are ignored. A value continues on following lines indented by two spaces,
which join with single spaces.

```
id: example-gospel-sampler
title: A Gospel sampler
version: 1
creator: Day by Word
summary: Five short readings from the Gospels, for a first week of
  reading.
suits: Readers trying a daily reading for the first time.
schedule: sequence
behaviors: pace, finish-date
reading-days: 5
coverage: selection
canon: protestant
books: MAT, MRK, LUK, JHN
limitations: Short passages chosen for a first week; it reads no book whole.
instructions: Read one passage a sitting, in any Bible.
source: An original plan by Day by Word.
rights: daybyword-original
review: checked
---
1	MRK 1:1-20
2	LUK 15
3	JHN 3:1-21
4	MAT 5:1-16
5	JHN 20:1-18; JHN 20:19-31
```

## Front matter

Every key is required, appears once, and comes in this order; an unknown
key is an error. Reader-facing values follow AGENTS.md §3: what the plan is,
whom it suits, its workload and coverage, and its limitations, never a
sermon.

| Key | Value |
|---|---|
| `id` | The plan's id (`PlanID`, docs/urls.md), the same as the file name. It never changes. |
| `title` | The exact title, with its edition where it has one. |
| `version` | A whole number from 1, raised with every published change (P4.6). |
| `creator` | Who made the plan: "Day by Word" for original plans. |
| `summary` | A short explanation of the plan, for its page. |
| `suits` | Whom it suits, in practical terms (time, goals, reading days). |
| `schedule` | `sequence` (numbered readings in order) or `day-of-month` (a reading for each day of the month). |
| `behaviors` | The behaviors the reader may choose, joined by `, `: `pace` and `finish-date` for a sequence, `calendar` for a day-of-month plan. |
| `reading-days` | The reading days a week the plan is paced for, 1 to 7. The reader chooses which days; the rest are rest days. |
| `coverage` | The claim the compiler checks (P4.4): `whole-bible` (every verse of the canon), `books` (every verse of each listed book), or `selection` (passages from the listed books, with no claim to cover them). |
| `canon` | The canon the plan assumes, by its id in `books.json`. |
| `books` | The books it reads from, by USFM id in canonical order, joined by `, `. Every reading's books must be listed, and every listed book read from. A `whole-bible` plan writes `all`, meaning the canon's books. |
| `limitations` | What the plan does not do, stated beside what it does. |
| `instructions` | How to follow it, plainly. |
| `source` | The source note shown on the plan page. |
| `rights` | Its entry in `catalog/SOURCES.md`. |
| `review` | Its review level (`docs/editorial.md`): `checked`, `reviewed`, or `expert`. |

## The schedule

One line per assignment: its id, a tab, and its reading in the plan-file
reference format (`docs/scripture.md`). Every reading is checked against
the English versification.

- **A sequence** numbers its assignments from 1 in the order they are read,
  one line each, with no gaps when first published.
- **A day-of-month plan** has one line for each day from 1 to 31, keyed by
  the day. What happens on the 31st, and on the 29th and 30th of February,
  belongs to the engine's rules for the calendar behavior (P5.7), and the
  plan's `instructions` say it plainly.

## Stable assignment ids

An assignment's id is how the journal records it (E3), so a reader's
history must keep meaning the same reading across versions of the plan:

- An id is never reused for a different reading and never renumbered.
- A correction that changes a reading's references keeps its id (P4.6 and
  P28.3 cover what an enrollment then shows).
- A reading added to a sequence after publication takes the next unused
  number and its line goes where it is read, so a sequence's ids are in
  order only until its first insertion. "Reading 12" on Today counts the
  reading's place in the sequence, not its id.
- A reading removed from a sequence leaves its id unused for good.
- A day-of-month plan's ids are its days, so they never change.

## The compiled catalog

`make catalog` writes `build/catalog/Catalog.sqlite` (and copies it into the
app's bundle), replacing the old file only once the new one is complete. A
problem anywhere stops the build with the file and line, and writes
nothing. The database has these tables (`CatalogBuild.schemaVersion`):

- `catalog_meta`: `schema_version`, `build_mode`, `plans` (how many), and
  `content_sha256`, a SHA-256 of the scripture data and every plan's
  fields, assignments, and facts, the same wherever the catalog is built, so the app and the server can tell
  whether they hold the same catalog.
- `plans`: one row per plan, a column per front matter key (`reading-days`
  is `reading_days`).
- `assignments`: `plan_id`, `id`, `position` (from 1, in reading order),
  `reading`, in its shortest plan-file writing, and its `words`.
- `plan_facts`: what each plan's schedule covers, computed (below).
- `scripture`: `books.json` and `versification/english.tsv`, as compiled.

The app and the server open it with `Catalog` in `ReadingData`, which reads
it whole and read-only and refuses, with what to do, a missing file or one
of another schema. Its `scripture` table holds the book registry and the
English versification it was compiled with, so a reader needs nothing else
from `catalog/`. `make check` compiles it in both modes.

A development build includes every plan whose source is `cleared` or
`pending`. A release build (`RELEASE=1 make catalog`) leaves out plans below
`reviewed` and says which, and refuses a plan whose source is not `cleared`.
Either refuses a plan whose source is `rejected` or `reference`, or has no
entry.

## What the compiler adds

The compiler computes these from the schedule and never takes them from the
file (`PlanFacts`, AGENTS.md §6), for the plan page (P9.4):

- `verses` given, counting repeats, and `unique_verses`, each once;
- `repeats`, the verses given more than once, and `omitted`, the verses of
  the listed books that no reading gives, each as the fewest passages in
  plan-file writing (empty when there are none);
- `whole_chapters` and `partial_chapters`, the chapters read in full and in
  part;
- the lightest, median, and heaviest reading's words (`words_minimum`,
  `words_median`, `words_maximum`), from which `Workload` gives minutes.

It refuses a claim the schedule does not support: a `whole-bible` or `books`
plan must leave nothing out, and the error names the first passages missing.
A `selection` claims no coverage to check. The sample week depends on the
reader's start date and reading days, so the engine computes it (P8.2).

## The export

`make catalog-export` writes `build/catalog/catalog-export.json` from the
release catalog (`catalog export`, `CatalogExport.swift`): the document the
server's PostgreSQL import reads. It holds the schema-3 data exactly as
compiled, so the same catalog always exports the same bytes:

- `format` (`daybyword-catalog-export`), `formatVersion` (1, raised when the
  document's meaning changes), `schemaVersion` (3), `buildMode`, and
  `contentSha256`, the catalog's own checksum;
- `plans`, in the compiler's order (by file name), each with every
  `plans` column in camel case, its `rightsStatus` from `SOURCES.md` at
  export, its `facts`, and its `assignments` by position;
- `scripture`, the `scripture` table's resources by name.

The importer (`web/src/catalog/export.ts`) recomputes `contentSha256` the
way the compiler does and refuses any difference, so it writes only the
catalog the compiler checked. It also refuses another format or schema; a
development build (unless asked, for local work); in a release, a plan
below `reviewed` or whose rights are not `cleared`; a `whole-bible` or
`books` claim with omissions; and assignments out of order.
`tests/fixtures/catalog-export.json` pins an invented release export that
the Swift and TypeScript tests both read.

## The server catalog

PostgreSQL's schema is `web/src/db/schema.ts`; drizzle-kit generates its SQL
into `web/drizzle/` (`make db-generate NAME=…`), and each migration is read
and committed. `make db-drift` fails when the schema has a change no
migration holds. The migration job (`web/scripts/db-migrate.ts`) and the
import job (`web/scripts/catalog-import.ts`) run once per deploy as
`daybyword_migrate`; the web server connects as `daybyword_app`, which may
only read (`web/db/roles.sql`).

- `plans`, `plan_facts`, and `assignments` are keyed by plan id **and
  version**. A version, once imported, never changes: importing different
  content under the same version is refused (raise the version), and the
  database refuses any update or delete of an imported row.
- Each import is a `catalog_imports` row with its checksum;
  `catalog_import_plans` says which plan versions it holds and in what order,
  `scripture_resources` holds its scripture, and `catalog_current` names the
  import being served.
- An import is one transaction under a lock: all of it is written and
  served, or nothing changes. Importing the same export again writes
  nothing; importing an earlier export serves it again (a rollback), with
  every version kept.
- A job refuses a database missing one of its migrations, or holding one it
  does not know (a newer build migrated it).

`make test-db` runs all of this against a throwaway PostgreSQL 17
(`scripts/with-postgres.sh`, a Unix socket only), with the fixture and the
repository's own release export.

